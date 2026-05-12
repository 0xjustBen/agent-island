import SwiftUI
import VibeCloneCore

@main
struct VibeCloneApp: App {
    @State private var controller = MenuBarController()

    var body: some Scene {
        MenuBarExtra {
            ApprovalPopover(controller: controller)
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
