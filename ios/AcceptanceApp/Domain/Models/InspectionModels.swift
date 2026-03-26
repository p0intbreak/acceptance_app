import Foundation
import SwiftUI
import UIKit

struct Apartment: Identifiable, Hashable {
    let id: String
    let title: String
    let address: String
}

struct Inspection: Identifiable, Hashable {
    let id: String
    let apartment: Apartment
    let plan: ApartmentPlan
}

struct ApartmentPlan: Hashable {
    let imageName: String
    let isometricImageName: String?
    let elements: [PlanElement]
}

struct PlanElement: Identifiable, Hashable {
    enum Kind: String, Hashable, CaseIterable {
        case wall
        case window
        case door
        case floor
        case ceiling
        case socket
    }

    let id: String
    let title: String
    let kind: Kind
    let contour: [NormalizedPoint]
    let labelAnchor: NormalizedPoint
}

struct NormalizedPoint: Hashable {
    let x: Double
    let y: Double
}

struct DefectReportDraft: Identifiable, Hashable {
    let id: String
    let inspectionId: String
    let planElement: PlanElement
    var comment: String
    var photos: [DefectPhoto]
}

struct DefectPhoto: Identifiable, Hashable {
    let id: String
    let filename: String
    let imageData: Data

    var previewImage: Image? {
        guard let uiImage = UIImage(data: imageData) else { return nil }
        return Image(uiImage: uiImage)
    }
}

struct VerificationResult: Hashable {
    enum Verdict: String, Hashable {
        case confirmed
        case doubtful
        case notEnoughEvidence
    }

    let verdict: Verdict
    let confidence: Double
    let explanation: String
    let recommendation: String
}
