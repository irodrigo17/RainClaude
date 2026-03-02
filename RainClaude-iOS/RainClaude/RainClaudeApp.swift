import SwiftUI

@main
struct RainClaudeApp: App {
    @StateObject private var placeStore = PlaceStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(placeStore)
        }
    }
}
