import Foundation

enum VerificationAPIError: LocalizedError {
    case invalidBaseURL
    case invalidResponse
    case reportCreationFailed
    case uploadFailed
    case verificationFailed
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "Не задан адрес backend API."
        case .invalidResponse:
            return "Backend вернул неожиданный ответ."
        case .reportCreationFailed:
            return "Не удалось создать отчёт о дефекте."
        case .uploadFailed:
            return "Не удалось загрузить фотографии дефекта."
        case .verificationFailed:
            return "Не удалось получить результат AI-проверки."
        case .requestFailed(let message):
            return message
        }
    }
}

struct VerificationAPIClient {
    let baseURL: URL
    let session: URLSession

    init(baseURL: URL, session: URLSession = .configuredForVerification()) {
        self.baseURL = baseURL
        self.session = session
    }

    func createReport(from draft: DefectReportDraft) async throws -> String {
        let requestBody = CreateReportRequest(
            inspectionId: draft.inspectionId,
            planElementId: draft.planElement.id,
            comment: draft.comment
        )

        var request = URLRequest(url: baseURL.appending(path: "v1/reports"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await send(request)
        try validate(data: data, response: response, failure: .reportCreationFailed)

        let decoded = try JSONDecoder().decode(CreateReportResponse.self, from: data)
        return decoded.reportId
    }

    func uploadPhotos(reportId: String, photos: [DefectPhoto]) async throws {
        guard !photos.isEmpty else { return }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: baseURL.appending(path: "v1/reports/\(reportId)/photos"))
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = multipartData(for: photos, boundary: boundary)

        let (data, response) = try await send(request)
        try validate(data: data, response: response, failure: .uploadFailed)
    }

    func verify(reportId: String) async throws -> VerificationResult {
        var request = URLRequest(url: baseURL.appending(path: "v1/reports/\(reportId)/verify"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(VerifyRequest(mode: "standard"))

        let (data, response) = try await send(request)
        try validate(data: data, response: response, failure: .verificationFailed)

        let decoded = try JSONDecoder().decode(VerifyResponse.self, from: data)
        return VerificationResult(
            verdict: .init(rawValue: decoded.verdict) ?? .doubtful,
            confidence: decoded.confidence,
            explanation: decoded.explanation,
            recommendation: decoded.recommendation
        )
    }

    private func multipartData(for photos: [DefectPhoto], boundary: String) -> Data {
        var data = Data()

        for photo in photos {
            data.append("--\(boundary)\r\n")
            data.append("Content-Disposition: form-data; name=\"photos\"; filename=\"\(photo.filename)\"\r\n")
            data.append("Content-Type: image/jpeg\r\n\r\n")
            data.append(photo.imageData)
            data.append("\r\n")
        }

        data.append("--\(boundary)--\r\n")
        return data
    }

    private func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            let nsError = error as NSError
            throw VerificationAPIError.requestFailed(
                "Сетевая ошибка \(nsError.code): \(nsError.localizedDescription)"
            )
        }
    }

    private func validate(data: Data, response: URLResponse, failure: VerificationAPIError) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw VerificationAPIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let responseText = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let suffix = responseText.flatMap { $0.isEmpty ? nil : " \($0)" } ?? ""
            switch httpResponse.statusCode {
            case 400...499:
                throw VerificationAPIError.requestFailed("HTTP \(httpResponse.statusCode).\(suffix)")
            case 500...599:
                throw VerificationAPIError.requestFailed("HTTP \(httpResponse.statusCode).\(suffix)")
            default:
                throw VerificationAPIError.invalidResponse
            }
        }
    }
}

private struct CreateReportRequest: Encodable {
    let inspectionId: String
    let planElementId: String
    let comment: String
}

private struct CreateReportResponse: Decodable {
    let reportId: String
}

private struct VerifyRequest: Encodable {
    let mode: String
}

private struct VerifyResponse: Decodable {
    let verdict: String
    let confidence: Double
    let explanation: String
    let recommendation: String
}

private extension Data {
    mutating func append(_ string: String) {
        if let encoded = string.data(using: .utf8) {
            append(encoded)
        }
    }
}

private extension URLSession {
    static func configuredForVerification() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 45
        configuration.timeoutIntervalForResource = 120
        return URLSession(configuration: configuration)
    }
}
