import Foundation

enum VerificationAPIError: LocalizedError {
    case invalidBaseURL
    case invalidResponse
    case reportCreationFailed
    case uploadFailed
    case verificationFailed

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
        }
    }
}

struct VerificationAPIClient {
    let baseURL: URL
    let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
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

        let (data, response) = try await session.data(for: request)
        try validate(response: response)

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

        let (_, response) = try await session.data(for: request)
        try validate(response: response)
    }

    func verify(reportId: String) async throws -> VerificationResult {
        var request = URLRequest(url: baseURL.appending(path: "v1/reports/\(reportId)/verify"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(VerifyRequest(mode: "standard"))

        let (data, response) = try await session.data(for: request)
        try validate(response: response)

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

    private func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw VerificationAPIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            switch httpResponse.statusCode {
            case 400...499:
                throw VerificationAPIError.reportCreationFailed
            case 500...599:
                throw VerificationAPIError.verificationFailed
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
