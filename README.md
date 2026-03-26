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

## Next Steps

1. Generate an Xcode project and wire these files into build targets.
2. Point `API_BASE_URL` to a real backend and switch `APP_VERIFICATION_MODE` to `remote`.
3. Add photo capture, upload queue, and persistence.
4. Connect a multimodal verification API on the backend.
