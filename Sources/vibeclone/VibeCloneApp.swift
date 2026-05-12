import SwiftUI
import VibeCloneCore

@main
struct VibeCloneApp: App {
    @State private var controller = MenuBarController()

    var body: some Scene {
        MenuBarExtra {
            // Task 17 replaces this stub with ApprovalPopover.
            VStack(alignment: .leading, spacing: 6) {
                Text("VibeClone").font(.headline)
                Text("Pending: \(controller.pendingCount)")
                Text("Active sessions: \(controller.activeSessionsCount)")
                Divider()
                Toggle("Auto-heal hooks", isOn: Binding(
                    get: { controller.prefs.autoHealHooks },
                    set: { controller.prefs.autoHealHooks = $0 }
                ))
                Button("Quit VibeClone") {
                    controller.shutdown()
                    NSApp.terminate(nil)
                }
            }
            .padding(12)
            .frame(width: 280)
        } label: {
            let count = controller.pendingCount
            if count > 0 {
                Image(systemName: "bell.badge.fill")
            } else {
                Image(systemName: "bell")
            }
        }
        .menuBarExtraStyle(.window)
    }
}
