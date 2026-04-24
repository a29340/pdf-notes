import SwiftUI

@main
struct PDFNotesApp: App {
    @StateObject private var store = DocumentStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
        #if os(macOS)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("PDF") {
                Button("Reset Viewer") {
                    store.reset()
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
        #endif
    }
}
