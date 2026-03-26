import Foundation

protocol InspectionRepository {
    func fetchInspections() async throws -> [Inspection]
}

protocol VerificationRepository {
    func verify(draft: DefectReportDraft) async throws -> VerificationResult
}

struct InMemoryInspectionRepository: InspectionRepository {
    func fetchInspections() async throws -> [Inspection] {
        [MVPPlanSeed.inspection]
    }
}

struct MockVerificationRepository: VerificationRepository {
    func verify(draft: DefectReportDraft) async throws -> VerificationResult {
        let normalized = draft.comment.lowercased()

        if normalized.contains("трещ") || normalized.contains("скол") {
            return VerificationResult(
                verdict: .confirmed,
                confidence: 0.84,
                explanation: "Описание указывает на конкретный визуальный дефект, и приложенные фото достаточны для предварительного подтверждения.",
                recommendation: "Дефект можно включать в акт приёмки."
            )
        }

        if draft.photos.isEmpty || draft.comment.count < 12 {
            return VerificationResult(
                verdict: .notEnoughEvidence,
                confidence: 0.34,
                explanation: "Фото или текст не дают достаточно контекста для уверенного вывода.",
                recommendation: "Добавьте крупный план и уточните, где именно расположен дефект."
            )
        }

        return VerificationResult(
            verdict: .doubtful,
            confidence: 0.51,
            explanation: "Описание выглядит правдоподобно, но визуальных признаков для уверенного подтверждения недостаточно.",
            recommendation: "Переснимите дефект при дневном свете и добавьте крупный план."
        )
    }
}

struct RemoteVerificationRepository: VerificationRepository {
    let apiClient: VerificationAPIClient

    func verify(draft: DefectReportDraft) async throws -> VerificationResult {
        let reportId = try await apiClient.createReport(from: draft)
        try await apiClient.uploadPhotos(reportId: reportId, photos: draft.photos)
        return try await apiClient.verify(reportId: reportId)
    }
}
