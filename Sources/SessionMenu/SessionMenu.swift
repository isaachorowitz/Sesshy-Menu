import SwiftUI

@main
struct SessionMenuApp: App {
    @State private var store = SessionStore()

    var body: some Scene {
        MenuBarExtra("Session Menu", systemImage: store.sessions.isEmpty ? "terminal" : "point.3.connected.trianglepath.dotted") {
            SessionMenuView()
                .environment(store)
                .task {
                    store.start()
                    await store.refresh()
                }
        }
        .menuBarExtraStyle(.window)
    }
}
