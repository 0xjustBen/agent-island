import SwiftUI
import AgentIslandCore

struct AgentIslandApp: App {
    @State private var controller = MenuBarController()

    var body: some Scene {
        MenuBarExtra {
            ApprovalPopover(controller: controller)
        } label: {
            let count = controller.pendingCount
            if count > 0 {
                Image(systemName: "hexagon.fill")
            } else {
                Image(systemName: "hexagon")
            }
        }
        .menuBarExtraStyle(.window)
    }
}
