import SwiftUI

private struct PlanContourShape: Shape {
    let points: [NormalizedPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }

        path.move(to: CGPoint(x: rect.minX + rect.width * first.x, y: rect.minY + rect.height * first.y))

        for point in points.dropFirst() {
            path.addLine(to: CGPoint(x: rect.minX + rect.width * point.x, y: rect.minY + rect.height * point.y))
        }

        path.closeSubpath()
        return path
    }
}

struct PlanView: View {
    private enum DisplayMode: String, CaseIterable, Identifiable {
        case twoD = "2D"
        case threeDLike = "3D-like"

        var id: String { rawValue }
    }

    let inspection: Inspection
    let submitReportUseCase: SubmitReportUseCase
    @State private var displayMode: DisplayMode = .twoD

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("План квартиры")
                    .font(.largeTitle.bold())

                Text(displayMode == .twoD
                     ? "Выберите элемент на плане, чтобы добавить дефект."
                     : "3D-like режим поможет визуально ориентироваться в квартире. Интерактивный выбор пока остаётся в 2D.")
                    .foregroundStyle(DesignTokens.Colors.muted)

                Picker("Режим плана", selection: $displayMode) {
                    ForEach(DisplayMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if displayMode == .twoD {
                    twoDPlan
                } else {
                    threeDLikePreview
                }
            }
            .padding(20)
        }
        .background(
            LinearGradient(
                colors: [Color.white, DesignTokens.Colors.surface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle(inspection.apartment.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var twoDPlan: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 28)
                .fill(DesignTokens.Colors.surface)
                .frame(height: 420)
                .overlay {
                    Group {
                        if inspection.plan.imageName.isEmpty {
                            Image(systemName: "square.split.2x2")
                                .font(.system(size: 120))
                                .foregroundStyle(DesignTokens.Colors.muted.opacity(0.22))
                        } else {
                            Image(inspection.plan.imageName)
                                .resizable()
                                .scaledToFit()
                                .padding(8)
                        }
                    }
                }

            GeometryReader { proxy in
                ForEach(inspection.plan.elements) { element in
                    NavigationLink {
                        DefectReportView(
                            inspectionId: inspection.id,
                            planElement: element,
                            submitReportUseCase: submitReportUseCase
                        )
                    } label: {
                        ZStack(alignment: .topLeading) {
                            PlanContourShape(points: element.contour)
                                .fill(DesignTokens.Colors.accent.opacity(0.001))
                                .contentShape(PlanContourShape(points: element.contour))

                            PlanContourShape(points: element.contour)
                                .stroke(DesignTokens.Colors.accent.opacity(0.16), lineWidth: 1)

                            Text(element.title)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(DesignTokens.Colors.ink)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.white.opacity(0.88))
                                .clipShape(Capsule())
                                .position(
                                    x: proxy.size.width * element.labelAnchor.x,
                                    y: proxy.size.height * element.labelAnchor.y
                                )
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                }
            }
            .frame(height: 420)
            .padding(12)
        }
    }

    private var threeDLikePreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            RoundedRectangle(cornerRadius: 28)
                .fill(DesignTokens.Colors.surface)
                .frame(height: 420)
                .overlay {
                    Group {
                        if let isometricImageName = inspection.plan.isometricImageName {
                            Image(isometricImageName)
                                .resizable()
                                .scaledToFit()
                                .padding(8)
                        } else {
                            VStack(spacing: 14) {
                                Image(systemName: "cube.transparent")
                                    .font(.system(size: 86))
                                    .foregroundStyle(DesignTokens.Colors.muted.opacity(0.45))

                                Text("3D-like preview")
                                    .font(.title3.bold())

                                Text("Сюда подключим изометрический рендер квартиры. Выбор дефектов пока остаётся через 2D-план.")
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(DesignTokens.Colors.muted)
                                    .padding(.horizontal, 28)
                            }
                        }
                    }
                }

            VStack(alignment: .leading, spacing: 10) {
                Text("Что будет в этом режиме")
                    .font(.headline)
                Text("1. Изометрический рендер квартиры")
                Text("2. Лёгкий pan и zoom на iPhone")
                Text("3. Мягкая подсветка выбранной комнаты или элемента")
                Text("4. Переход в карточку дефекта через основной 2D-слой")
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }
}
