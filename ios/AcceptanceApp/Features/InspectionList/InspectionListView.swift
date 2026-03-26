import SwiftUI

struct InspectionListView: View {
    @StateObject private var viewModel: InspectionListViewModel

    init(viewModel: InspectionListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List(viewModel.inspections) { inspection in
            NavigationLink {
                PlanView(
                    inspection: inspection,
                    submitReportUseCase: viewModel.submitReportUseCase
                )
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    Text(inspection.apartment.title)
                        .font(.headline)
                    Text(inspection.apartment.address)
                        .font(.subheadline)
                        .foregroundStyle(DesignTokens.Colors.muted)
                }
                .padding(.vertical, 6)
            }
        }
        .navigationTitle("Приёмка")
        .task {
            await viewModel.load()
        }
    }
}
