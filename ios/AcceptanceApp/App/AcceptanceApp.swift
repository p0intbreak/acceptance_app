import SwiftUI

@main
struct AcceptanceApp: App {
    private let container = AppContainer()

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
        }
    }
}
