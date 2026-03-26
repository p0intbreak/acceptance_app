# API Contracts

## Create Report

`POST /v1/reports`

```json
{
  "inspectionId": "inspection_001",
  "planElementId": "window_living_room_01",
  "comment": "Трещина на откосе окна и виден скол краски"
}
```

Response:

```json
{
  "reportId": "report_001",
  "status": "draft",
  "createdAt": "2026-03-26T12:00:00Z"
}
```

## Upload Report Photos

`POST /v1/reports/{reportId}/photos`

Multipart upload with up to three images. The backend returns uploaded asset metadata.

```json
{
  "photos": [
    {
      "photoId": "photo_001",
      "url": "https://storage.example.com/photo_001.jpg"
    }
  ]
}
```

## Trigger Verification

`POST /v1/reports/{reportId}/verify`

```json
{
  "mode": "standard"
}
```

Response:

```json
{
  "reportId": "report_001",
  "verdict": "confirmed",
  "confidence": 0.84,
  "explanation": "На фото виден дефект в области оконного откоса, описание совпадает с визуальными признаками.",
  "recommendation": "Можно включить в акт приёмки без пересъёмки.",
  "checkedAt": "2026-03-26T12:01:45Z"
}
```

## Verdict Enum

- `confirmed`
- `doubtful`
- `notEnoughEvidence`

## iOS MVP Integration Note

The current iPhone client uses the same three-step flow:

1. `POST /v1/reports`
2. `POST /v1/reports/{reportId}/photos`
3. `POST /v1/reports/{reportId}/verify`

To enable remote verification in the app, set `APP_VERIFICATION_MODE=remote` and `API_BASE_URL` in `Info.plist`.
