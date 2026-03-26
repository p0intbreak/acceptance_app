import Foundation

struct AppConfig {
    enum VerificationMode: String {
        case mock
        case remote
    }

    let verificationMode: VerificationMode
    let apiBaseURL: URL?

    static let current = AppConfig(bundle: .main)

    init(bundle: Bundle) {
        let rawMode = bundle.object(forInfoDictionaryKey: "APP_VERIFICATION_MODE") as? String ?? "mock"
        verificationMode = VerificationMode(rawValue: rawMode.lowercased()) ?? .mock

        if let baseURLString = bundle.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
           !baseURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            apiBaseURL = URL(string: baseURLString)
        } else {
            apiBaseURL = nil
        }
    }
}
