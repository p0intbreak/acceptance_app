import Foundation

@MainActor
final class AppContainer {
    let inspectionRepository: InspectionRepository
    let verificationRepository: VerificationRepository
    let submitReportUseCase: SubmitReportUseCase
    let config: AppConfig

    init() {
        let config = AppConfig.current
        let inspectionRepository = InMemoryInspectionRepository()
        let verificationRepository: VerificationRepository

        switch (config.verificationMode, config.apiBaseURL) {
        case (.remote, .some(let baseURL)):
            verificationRepository = RemoteVerificationRepository(
                apiClient: VerificationAPIClient(baseURL: baseURL)
            )
        default:
            verificationRepository = MockVerificationRepository()
        }

        self.config = config
        self.inspectionRepository = inspectionRepository
        self.verificationRepository = verificationRepository
        self.submitReportUseCase = SubmitReportUseCase(verificationRepository: verificationRepository)
    }
}
