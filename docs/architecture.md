# iPhone MVP Architecture

## Principles

- Native iPhone app instead of cross-platform stack
- Thin client for capture and review, server-side AI verification
- Fixed plan annotations in MVP, no on-device editor
- Offline-friendly draft creation with later upload

## Feature Flow

1. User opens an inspection.
2. App shows a 2D apartment plan.
3. User taps a plan element such as a wall or window.
4. App opens a defect report screen for that element.
5. User attaches up to three photos and enters one shared comment.
6. App uploads report payload and photos.
7. Backend runs multimodal verification.
8. App shows a verdict and explanation.

## Module Boundaries

```text
AcceptanceApp
├── App
│   ├── AppEntry
│   └── DependencyContainer
├── Core
│   ├── Routing
│   └── DesignSystem
├── Domain
│   ├── Models
│   └── UseCases
├── Data
│   ├── API
│   └── Repositories
├── Features
│   ├── InspectionList
│   ├── PlanViewer
│   ├── DefectReporting
│   └── Verification
└── Shared
    └── Camera
```

## Architectural Decisions

### UI

- `SwiftUI` for screens, navigation, forms, and media previews
- `NavigationStack` for flow control
- `Observable` or `ObservableObject` view models per feature

### Domain

- Keep domain models free from UI and transport concerns
- Express verification as a use case so backend implementation can change without rewriting features
- Bind plan selection to normalized contour points, not coarse rectangular frames

### Data

- Repositories hide API and local persistence details
- Draft reports should be persisted locally before upload
- Photo compression happens in a shared media service before network transfer
- Verification transport supports `mock` and `remote` modes through app configuration

### AI Verification

- Performed on backend, not on device
- Request contains the plan element, free-text comment, and image set
- Response returns a structured verdict, confidence, and human-readable explanation

## MVP Risks

- Some defects are not visually verifiable from user photos alone
- Lighting and distance can lower model confidence
- Text may describe defects outside the photographed area

Because of that, the backend contract should support `notEnoughEvidence` as a distinct state even if the first UI maps it to a "сомнительно" label.

## 2D vs 3D-like Strategy

- `2D` stays the source of truth for element selection and defect binding
- `3D-like` is an auxiliary visualization mode for spatial orientation
- A real 3D engine should only be introduced after the 2D contour model is stable
