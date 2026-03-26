import SwiftUI

struct VerificationResultCard: View {
    let result: VerificationResult

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundStyle(.white)
                .background(badgeColor)
                .clipShape(Capsule())

            Text("Уверенность: \(Int(result.confidence * 100))%")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.ink)

            Text(result.explanation)
                .foregroundStyle(DesignTokens.Colors.ink)

            Text(result.recommendation)
                .foregroundStyle(DesignTokens.Colors.muted)
        }
        .padding(18)
        .background(.white.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var title: String {
        switch result.verdict {
        case .confirmed:
            return "Подтверждено"
        case .doubtful:
            return "Сомнительно"
        case .notEnoughEvidence:
            return "Недостаточно данных"
        }
    }

    private var badgeColor: Color {
        switch result.verdict {
        case .confirmed:
            return DesignTokens.Colors.confirmed
        case .doubtful:
            return DesignTokens.Colors.doubtful
        case .notEnoughEvidence:
            return DesignTokens.Colors.evidence
        }
    }
}
