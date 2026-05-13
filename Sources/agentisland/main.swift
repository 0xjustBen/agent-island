import Foundation
import AppKit

// CLI fast-path: --doctor / --version exit before launching the SwiftUI app.
if MainActor.assumeIsolated({ Diagnostics.runIfRequested() }) {
    exit(0)
}

AgentIslandApp.main()
