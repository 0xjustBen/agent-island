import SwiftUI
import VibeCloneCore

struct VibeCloneApp: App {
    @State private var controller = MenuBarController()

    var body: some Scene {
        MenuBarExtra {
            ApprovalPopover(controller: controller)
        } label: {
            let count = controller.pendingCount
            if count > 0 {
                Image(systemName: "hexagon.fill")
            } else {
                Image(systemName: "hexagongrid")
            }
        }
        .menuBarExtraStyle(.window)
    }
}
