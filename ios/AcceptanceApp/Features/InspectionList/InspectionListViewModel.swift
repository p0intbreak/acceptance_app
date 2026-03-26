import Foundation

@MainActor
final class InspectionListViewModel: ObservableObject {
    @Published private(set) var inspections: [Inspection] = []
    @Published var selectedResult: VerificationResult?

    private let repository: InspectionRepository
    let submitReportUseCase: SubmitReportUseCase

    init(repository: InspectionRepository, submitReportUseCase: SubmitReportUseCase) {
        self.repository = repository
        self.submitReportUseCase = submitReportUseCase
    }

    func load() async {
        do {
            inspections = try await repository.fetchInspections()
        } catch {
            inspections = []
        }
    }
}
