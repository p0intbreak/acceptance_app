import SwiftUI

struct RootView: View {
    let container: AppContainer

    var body: some View {
        NavigationStack {
            InspectionListView(
                viewModel: InspectionListViewModel(
                    repository: container.inspectionRepository,
                    submitReportUseCase: container.submitReportUseCase
                )
            )
        }
        .tint(DesignTokens.Colors.accent)
    }
}
