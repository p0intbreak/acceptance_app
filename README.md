# Acceptance App

MVP for an iPhone apartment acceptance app. The user opens a 2D apartment plan, taps a plan element, attaches up to three photos, writes one shared defect comment, and sends the report for AI verification.

## Product Scope

- iPhone only
- 2D plan with predefined tappable zones
- Defect card with up to 3 photos
- One shared text comment per report
- AI result: `confirmed`, `doubtful`, or `notEnoughEvidence`

## Repository Layout

```text
ios/
  AcceptanceApp/
    App/
    Core/
    Data/
    Domain/
    Features/
    Shared/
docs/
api/
backend/
```

## Recommended Stack

- UI: SwiftUI
- State: MVVM
- Local storage: SwiftData
- Networking: URLSession
- Media: PhotosPicker, AVFoundation
- Backend: FastAPI or NestJS
- Image storage: S3-compatible object storage

## Current Contents

- iPhone architecture scaffold
- SwiftUI flow skeleton
- domain model draft
- API contracts for report creation and AI verification
- real MVP plan image in `assets/plans/apartment_plan_mvp.jpeg`
- remote verification client with mock/remote switch via `Info.plist`
- FastAPI backend for report creation, photo upload, and OpenAI-based verification

## Running The Backend

Local run:

```bash
cd "/Users/olegtikhonov/Documents/New project/acceptance_app"
source .venv/bin/activate
uvicorn backend.app.main:app --host 0.0.0.0 --port 8000
```

Health check:

```bash
curl http://127.0.0.1:8000/health
```

If `OPENAI_API_KEY` is not set, the backend still runs but falls back to heuristic verification.

## Deployed Backend

- Current public backend URL: `http://68.183.6.233:8000`
- Current health response: `{"status":"ok","mode":"mock"}`
- Server process: `systemd` service `acceptance_backend`
- Deployment path on server: `/root/acceptance_app`
- To switch from heuristic mode to real OpenAI verification, set a valid `OPENAI_API_KEY` in `/root/acceptance_app/.env` and restart the service:

```bash
ssh root@68.183.6.233
nano /root/acceptance_app/.env
systemctl restart acceptance_backend
```

## iPhone Backend Setup

- Current backend URL in `Info.plist`: `http://68.183.6.233:8000`
- Current verification mode in `Info.plist`: `remote`
- ATS is opened for HTTP during MVP development
- Rebuild the app in Xcode after changing `Info.plist`

## Next Steps

1. Put a real `OPENAI_API_KEY` into `/root/acceptance_app/.env`.
2. Restart `acceptance_backend` on the server.
3. Rebuild the iPhone app with the current `Info.plist`.
4. Test the full chain with real photos from the device.
