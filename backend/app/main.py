from __future__ import annotations

import base64
import json
import logging
import mimetypes
import os
import uuid
from dataclasses import dataclass, field
from pathlib import Path
from typing import Literal
from urllib import error, request

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, ConfigDict


APP_DIR = Path(__file__).resolve().parents[1]
ROOT_DIR = APP_DIR.parent
STORAGE_DIR = ROOT_DIR / "storage"
REPORTS_DIR = STORAGE_DIR / "reports"
REPORTS_DIR.mkdir(parents=True, exist_ok=True)
logger = logging.getLogger("acceptance_backend")
logging.basicConfig(level=logging.INFO)


def load_dotenv(path: Path) -> None:
    if not path.exists():
        return

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip())


def normalize_api_key(raw_value: str) -> str:
    value = raw_value.strip()
    if not value or value in {"your_openai_api_key", "changeme", "replace_me"}:
        return ""
    return value


load_dotenv(ROOT_DIR / ".env")

KIMI_API_KEY = normalize_api_key(os.getenv("KIMI_API_KEY", ""))
KIMI_BASE_URL = os.getenv("KIMI_BASE_URL", "https://api.moonshot.cn/v1").rstrip("/")
KIMI_MODEL = os.getenv("KIMI_MODEL", "kimi-k2.5")
OPENAI_API_KEY = normalize_api_key(os.getenv("OPENAI_API_KEY", ""))
OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-4.1-mini")


class CreateReportRequest(BaseModel):
    inspectionId: str
    planElementId: str
    comment: str


class CreateReportResponse(BaseModel):
    reportId: str
    status: str
    createdAt: str


class UploadedPhotoResponse(BaseModel):
    photoId: str
    url: str


class UploadPhotosResponse(BaseModel):
    photos: list[UploadedPhotoResponse]


class VerifyRequest(BaseModel):
    mode: str = "standard"


class VerifyResponse(BaseModel):
    reportId: str
    verdict: Literal["confirmed", "doubtful", "notEnoughEvidence"]
    confidence: float
    explanation: str
    recommendation: str
    checkedAt: str


class StoredPhoto(BaseModel):
    id: str
    filename: str
    path: str
    mimeType: str


class StoredReport(BaseModel):
    model_config = ConfigDict(protected_namespaces=())

    id: str
    inspectionId: str
    planElementId: str
    comment: str
    status: str
    createdAt: str
    photos: list[StoredPhoto] = []
    verification: VerifyResponse | None = None


@dataclass
class ReportStore:
    reports_dir: Path
    reports: dict[str, StoredReport] = field(default_factory=dict)

    def create(self, payload: CreateReportRequest) -> StoredReport:
        report_id = f"report_{uuid.uuid4().hex[:12]}"
        report = StoredReport(
            id=report_id,
            inspectionId=payload.inspectionId,
            planElementId=payload.planElementId,
            comment=payload.comment,
            status="draft",
            createdAt=iso_now(),
        )
        self.reports[report_id] = report
        self._persist(report)
        return report

    def get(self, report_id: str) -> StoredReport:
        report = self.reports.get(report_id)
        if report is None:
            report = self._load(report_id)
            if report is None:
                raise KeyError(report_id)
            self.reports[report_id] = report
        return report

    def save(self, report: StoredReport) -> None:
        self.reports[report.id] = report
        self._persist(report)

    def _report_dir(self, report_id: str) -> Path:
        return self.reports_dir / report_id

    def _report_file(self, report_id: str) -> Path:
        return self._report_dir(report_id) / "report.json"

    def _persist(self, report: StoredReport) -> None:
        report_dir = self._report_dir(report.id)
        report_dir.mkdir(parents=True, exist_ok=True)
        self._report_file(report.id).write_text(
            json.dumps(report.model_dump(mode="json"), ensure_ascii=False, indent=2),
            encoding="utf-8",
        )

    def _load(self, report_id: str) -> StoredReport | None:
        report_file = self._report_file(report_id)
        if not report_file.exists():
            return None
        return StoredReport.model_validate_json(report_file.read_text(encoding="utf-8"))


class ExternalVerificationService:
    def __init__(
        self,
        kimi_api_key: str,
        kimi_base_url: str,
        kimi_model: str,
        openai_api_key: str,
        openai_model: str,
    ) -> None:
        self.kimi_api_key = kimi_api_key
        self.kimi_base_url = kimi_base_url
        self.kimi_model = kimi_model
        self.openai_api_key = openai_api_key
        self.openai_model = openai_model

    def verify(self, report: StoredReport) -> VerifyResponse:
        if self.kimi_api_key:
            return self._verify_with_kimi(report)

        if self.openai_api_key:
            return self._verify_with_openai(report)

        return heuristic_verification(report)

    def _verify_with_kimi(self, report: StoredReport) -> VerifyResponse:
        try:
            logger.info("Starting Kimi verification for report %s", report.id)
            payload = build_kimi_payload(report, model=self.kimi_model)
            response = request.urlopen(
                request.Request(
                    url=f"{self.kimi_base_url}/chat/completions",
                    headers={
                        "Authorization": f"Bearer {self.kimi_api_key}",
                        "Content-Type": "application/json",
                    },
                    data=json.dumps(payload).encode("utf-8"),
                    method="POST",
                ),
                timeout=25,
            )
            raw = json.loads(response.read().decode("utf-8"))
            parsed_text = extract_kimi_content(raw)
            parsed = parse_json_payload(parsed_text)
            logger.info("Kimi verification succeeded for report %s", report.id)
            return build_verify_response(report.id, parsed)
        except error.HTTPError as exc:
            details = exc.read().decode("utf-8", errors="ignore")
            logger.error("Kimi HTTP error for report %s: %s", report.id, details)
            raise HTTPException(status_code=502, detail=f"Kimi API error: {details}") from exc
        except Exception as exc:
            logger.exception("Kimi verification failed for report %s", report.id)
            raise HTTPException(status_code=500, detail=f"Kimi verification failed: {exc}") from exc

    def _verify_with_openai(self, report: StoredReport) -> VerifyResponse:
        try:
            payload = build_openai_payload(report, model=self.openai_model)
            response = request.urlopen(
                request.Request(
                    url="https://api.openai.com/v1/responses",
                    headers={
                        "Authorization": f"Bearer {self.openai_api_key}",
                        "Content-Type": "application/json",
                    },
                    data=json.dumps(payload).encode("utf-8"),
                    method="POST",
                ),
                timeout=25,
            )
            raw = json.loads(response.read().decode("utf-8"))
            parsed_text = extract_output_text(raw)
            parsed = parse_json_payload(parsed_text)
            return build_verify_response(report.id, parsed)
        except error.HTTPError as exc:
            details = exc.read().decode("utf-8", errors="ignore")
            raise HTTPException(status_code=502, detail=f"OpenAI API error: {details}") from exc
        except Exception as exc:
            raise HTTPException(status_code=500, detail=f"OpenAI verification failed: {exc}") from exc


def build_openai_payload(report: StoredReport, model: str) -> dict:
    user_content: list[dict[str, str]] = [
        {
            "type": "input_text",
            "text": (
                "Проверь, подтверждается ли дефект на фотографиях. "
                f"Элемент квартиры: {report.planElementId}. "
                f"Комментарий пользователя: {report.comment}"
            ),
        }
    ]

    for photo in report.photos:
        image_path = Path(photo.path)
        image_b64 = base64.b64encode(image_path.read_bytes()).decode("utf-8")
        user_content.append(
            {
                "type": "input_image",
                "detail": "high",
                "image_url": f"data:{photo.mimeType};base64,{image_b64}",
            }
        )

    return {
        "model": model,
        "input": [
            {
                "role": "developer",
                "content": [
                    {
                        "type": "input_text",
                        "text": (
                            "Ты проверяешь дефекты квартиры по 1-3 фотографиям и общему комментарию. "
                            "Отвечай строго по схеме. "
                            "Если дефект отчётливо виден и соответствует описанию, verdict=confirmed. "
                            "Если есть слабые признаки или не хватает уверенности, verdict=doubtful. "
                            "Если фото или описание недостаточны, verdict=notEnoughEvidence. "
                            "Confidence должен быть числом от 0 до 1."
                        ),
                    }
                ],
            },
            {
                "role": "user",
                "content": user_content,
            },
        ],
        "text": {
            "format": {
                "type": "json_schema",
                "name": "defect_verification",
                "strict": True,
                "schema": {
                    "type": "object",
                    "properties": {
                        "verdict": {
                            "type": "string",
                            "enum": ["confirmed", "doubtful", "notEnoughEvidence"],
                        },
                        "confidence": {"type": "number"},
                        "explanation": {"type": "string"},
                        "recommendation": {"type": "string"},
                    },
                    "required": ["verdict", "confidence", "explanation", "recommendation"],
                    "additionalProperties": False,
                },
            }
        },
    }


def build_kimi_payload(report: StoredReport, model: str) -> dict:
    user_content: list[dict[str, object]] = [
        {
            "type": "text",
            "text": (
                "Проверь, подтверждается ли дефект на фотографиях. "
                f"Элемент квартиры: {report.planElementId}. "
                f"Комментарий пользователя: {report.comment}"
            ),
        }
    ]

    for photo in report.photos:
        image_path = Path(photo.path)
        image_b64 = base64.b64encode(image_path.read_bytes()).decode("utf-8")
        user_content.append(
            {
                "type": "image_url",
                "image_url": {
                    "url": f"data:{photo.mimeType};base64,{image_b64}",
                },
            }
        )

    return {
        "model": model,
        "temperature": 0.1,
        "messages": [
            {
                "role": "system",
                "content": (
                    "Ты проверяешь дефекты квартиры по 1-3 фотографиям и общему комментарию. "
                    "Верни только JSON без markdown и пояснений вокруг него. "
                    "Поля: verdict, confidence, explanation, recommendation. "
                    "verdict должен быть одним из: confirmed, doubtful, notEnoughEvidence. "
                    "confidence должен быть числом от 0 до 1."
                ),
            },
            {
                "role": "user",
                "content": user_content,
            },
        ],
    }


def extract_output_text(raw_response: dict) -> str:
    for item in raw_response.get("output", []):
        if item.get("type") != "message":
            continue
        for content in item.get("content", []):
            if content.get("type") == "output_text":
                return content.get("text", "")
    raise ValueError("No output_text found in OpenAI response")


def extract_kimi_content(raw_response: dict) -> str:
    choices = raw_response.get("choices", [])
    if not choices:
        raise ValueError("No choices found in Kimi response")

    message = choices[0].get("message", {})
    content = message.get("content", "")
    if isinstance(content, str):
        return content
    raise ValueError("No textual content found in Kimi response")


def parse_json_payload(raw_text: str) -> dict:
    text = raw_text.strip()
    if text.startswith("```"):
        text = text.strip("`")
        if text.startswith("json"):
            text = text[4:].strip()
    start = text.find("{")
    end = text.rfind("}")
    if start == -1 or end == -1:
        raise ValueError("No JSON object found in model response")
    return json.loads(text[start : end + 1])


def build_verify_response(report_id: str, parsed: dict) -> VerifyResponse:
    return VerifyResponse(
        reportId=report_id,
        verdict=parsed["verdict"],
        confidence=float(parsed["confidence"]),
        explanation=parsed["explanation"],
        recommendation=parsed["recommendation"],
        checkedAt=iso_now(),
    )


def heuristic_verification(report: StoredReport) -> VerifyResponse:
    normalized = report.comment.lower()

    if not report.photos or len(report.comment.strip()) < 12:
        verdict = "notEnoughEvidence"
        confidence = 0.31
        explanation = "Недостаточно данных: либо мало фото, либо описание слишком короткое."
        recommendation = "Добавьте крупный план и точнее опишите дефект."
    elif any(token in normalized for token in ("трещ", "скол", "царап", "протеч", "плесен")):
        verdict = "confirmed"
        confidence = 0.78
        explanation = "Описание похоже на конкретный визуальный дефект; фото подходят для предварительного подтверждения."
        recommendation = "Зафиксируйте дефект в акте и при необходимости добавьте ещё один крупный план."
    else:
        verdict = "doubtful"
        confidence = 0.52
        explanation = "Описание выглядит правдоподобно, но без явных визуальных признаков подтверждение остаётся сомнительным."
        recommendation = "Сделайте дополнительный снимок при лучшем освещении."

    return VerifyResponse(
        reportId=report.id,
        verdict=verdict,
        confidence=confidence,
        explanation=explanation,
        recommendation=recommendation,
        checkedAt=iso_now(),
    )


def iso_now() -> str:
    from datetime import datetime, timezone

    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


store = ReportStore(REPORTS_DIR)
verification_service = ExternalVerificationService(
    kimi_api_key=KIMI_API_KEY,
    kimi_base_url=KIMI_BASE_URL,
    kimi_model=KIMI_MODEL,
    openai_api_key=OPENAI_API_KEY,
    openai_model=OPENAI_MODEL,
)

app = FastAPI(title="Acceptance App Backend", version="0.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health() -> dict[str, str]:
    if KIMI_API_KEY:
        mode = "remote-kimi"
    elif OPENAI_API_KEY:
        mode = "remote-openai"
    else:
        mode = "mock"
    return {"status": "ok", "mode": mode}


@app.post("/v1/reports", response_model=CreateReportResponse)
def create_report(payload: CreateReportRequest) -> CreateReportResponse:
    report = store.create(payload)
    return CreateReportResponse(
        reportId=report.id,
        status=report.status,
        createdAt=report.createdAt,
    )


@app.post("/v1/reports/{report_id}/photos", response_model=UploadPhotosResponse)
async def upload_photos(report_id: str, photos: list[UploadFile] = File(...)) -> UploadPhotosResponse:
    if len(photos) > 3:
        raise HTTPException(status_code=400, detail="At most 3 photos are allowed")

    try:
        report = store.get(report_id)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail="Report not found") from exc

    saved_photos: list[UploadedPhotoResponse] = []
    report_dir = REPORTS_DIR / report_id / "photos"
    report_dir.mkdir(parents=True, exist_ok=True)

    for upload in photos:
        extension = Path(upload.filename or "photo.jpg").suffix or ".jpg"
        photo_id = f"photo_{uuid.uuid4().hex[:10]}"
        target_path = report_dir / f"{photo_id}{extension}"
        content = await upload.read()
        target_path.write_bytes(content)

        mime_type = upload.content_type or mimetypes.guess_type(target_path.name)[0] or "image/jpeg"
        stored = StoredPhoto(
            id=photo_id,
            filename=upload.filename or target_path.name,
            path=str(target_path),
            mimeType=mime_type,
        )
        report.photos.append(stored)
        saved_photos.append(UploadedPhotoResponse(photoId=photo_id, url=str(target_path)))

    store.save(report)
    return UploadPhotosResponse(photos=saved_photos)


@app.post("/v1/reports/{report_id}/verify", response_model=VerifyResponse)
def verify_report(report_id: str, payload: VerifyRequest) -> VerifyResponse:
    _ = payload
    try:
        report = store.get(report_id)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail="Report not found") from exc

    logger.info("Verify requested for report %s", report_id)
    verification = verification_service.verify(report)
    report.status = "verified"
    report.verification = verification
    store.save(report)
    return verification
