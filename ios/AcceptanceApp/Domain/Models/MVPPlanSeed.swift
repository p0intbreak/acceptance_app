import Foundation

enum MVPPlanSeed {
    static let apartment = Apartment(
        id: "apt_001",
        title: "Квартира MVP",
        address: "Тестовый объект, реальный план пользователя"
    )

    static let inspection = Inspection(
        id: "inspection_001",
        apartment: apartment,
        plan: ApartmentPlan(
            imageName: "apartment_plan_mvp",
            isometricImageName: nil,
            elements: [
                PlanElement(
                    id: "bathroom_01",
                    title: "Санузел",
                    kind: .ceiling,
                    contour: [
                        NormalizedPoint(x: 0.17, y: 0.03),
                        NormalizedPoint(x: 0.50, y: 0.03),
                        NormalizedPoint(x: 0.50, y: 0.28),
                        NormalizedPoint(x: 0.40, y: 0.28),
                        NormalizedPoint(x: 0.40, y: 0.19),
                        NormalizedPoint(x: 0.29, y: 0.19),
                        NormalizedPoint(x: 0.29, y: 0.28),
                        NormalizedPoint(x: 0.17, y: 0.28)
                    ],
                    labelAnchor: NormalizedPoint(x: 0.28, y: 0.14)
                ),
                PlanElement(
                    id: "hallway_01",
                    title: "Прихожая",
                    kind: .floor,
                    contour: [
                        NormalizedPoint(x: 0.00, y: 0.29),
                        NormalizedPoint(x: 0.58, y: 0.29),
                        NormalizedPoint(x: 0.58, y: 0.44),
                        NormalizedPoint(x: 0.50, y: 0.44),
                        NormalizedPoint(x: 0.50, y: 0.40),
                        NormalizedPoint(x: 0.39, y: 0.40),
                        NormalizedPoint(x: 0.39, y: 0.47),
                        NormalizedPoint(x: 0.13, y: 0.47),
                        NormalizedPoint(x: 0.13, y: 0.40),
                        NormalizedPoint(x: 0.00, y: 0.40)
                    ],
                    labelAnchor: NormalizedPoint(x: 0.32, y: 0.36)
                ),
                PlanElement(
                    id: "bedroom_01",
                    title: "Спальня",
                    kind: .floor,
                    contour: [
                        NormalizedPoint(x: 0.52, y: 0.03),
                        NormalizedPoint(x: 0.94, y: 0.03),
                        NormalizedPoint(x: 0.94, y: 0.42),
                        NormalizedPoint(x: 0.53, y: 0.42),
                        NormalizedPoint(x: 0.53, y: 0.29),
                        NormalizedPoint(x: 0.50, y: 0.29),
                        NormalizedPoint(x: 0.50, y: 0.03)
                    ],
                    labelAnchor: NormalizedPoint(x: 0.78, y: 0.34)
                ),
                PlanElement(
                    id: "kitchen_01",
                    title: "Кухня",
                    kind: .floor,
                    contour: [
                        NormalizedPoint(x: 0.17, y: 0.49),
                        NormalizedPoint(x: 0.34, y: 0.49),
                        NormalizedPoint(x: 0.34, y: 0.93),
                        NormalizedPoint(x: 0.17, y: 0.93)
                    ],
                    labelAnchor: NormalizedPoint(x: 0.26, y: 0.72)
                ),
                PlanElement(
                    id: "living_room_01",
                    title: "Гостиная",
                    kind: .floor,
                    contour: [
                        NormalizedPoint(x: 0.35, y: 0.43),
                        NormalizedPoint(x: 0.93, y: 0.43),
                        NormalizedPoint(x: 0.93, y: 0.93),
                        NormalizedPoint(x: 0.35, y: 0.93),
                        NormalizedPoint(x: 0.35, y: 0.48),
                        NormalizedPoint(x: 0.50, y: 0.48),
                        NormalizedPoint(x: 0.50, y: 0.43)
                    ],
                    labelAnchor: NormalizedPoint(x: 0.76, y: 0.74)
                ),
                PlanElement(
                    id: "bedroom_window_01",
                    title: "Окно спальни",
                    kind: .window,
                    contour: [
                        NormalizedPoint(x: 0.95, y: 0.09),
                        NormalizedPoint(x: 0.99, y: 0.09),
                        NormalizedPoint(x: 0.99, y: 0.35),
                        NormalizedPoint(x: 0.95, y: 0.35)
                    ],
                    labelAnchor: NormalizedPoint(x: 0.90, y: 0.18)
                ),
                PlanElement(
                    id: "living_window_01",
                    title: "Окно гостиной",
                    kind: .window,
                    contour: [
                        NormalizedPoint(x: 0.95, y: 0.54),
                        NormalizedPoint(x: 0.99, y: 0.54),
                        NormalizedPoint(x: 0.99, y: 0.85),
                        NormalizedPoint(x: 0.95, y: 0.85)
                    ],
                    labelAnchor: NormalizedPoint(x: 0.87, y: 0.63)
                ),
                PlanElement(
                    id: "kitchen_wall_01",
                    title: "Стена кухни слева",
                    kind: .wall,
                    contour: [
                        NormalizedPoint(x: 0.12, y: 0.50),
                        NormalizedPoint(x: 0.17, y: 0.50),
                        NormalizedPoint(x: 0.17, y: 0.93),
                        NormalizedPoint(x: 0.12, y: 0.93)
                    ],
                    labelAnchor: NormalizedPoint(x: 0.22, y: 0.84)
                ),
                PlanElement(
                    id: "living_wall_01",
                    title: "Стена гостиной сверху",
                    kind: .wall,
                    contour: [
                        NormalizedPoint(x: 0.51, y: 0.43),
                        NormalizedPoint(x: 0.89, y: 0.43),
                        NormalizedPoint(x: 0.89, y: 0.47),
                        NormalizedPoint(x: 0.51, y: 0.47)
                    ],
                    labelAnchor: NormalizedPoint(x: 0.68, y: 0.51)
                )
            ]
        )
    )
}
