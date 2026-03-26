import Foundation

struct SubmitReportUseCase {
    let verificationRepository: VerificationRepository

    func execute(draft: DefectReportDraft) async throws -> VerificationResult {
        try await verificationRepository.verify(draft: draft)
    }
}
