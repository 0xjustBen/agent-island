import AppKit
import Carbon.HIToolbox

@MainActor
final class HotkeyMonitor {
    private var monitor: Any?
    private let onTrigger: () -> Void

    init(onTrigger: @escaping () -> Void) {
        self.onTrigger = onTrigger
    }

    func start() {
        let mask: NSEvent.ModifierFlags = [.control, .shift]
        let trigger = self.onTrigger
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == mask,
               event.keyCode == kVK_ANSI_V {
                MainActor.assumeIsolated {
                    trigger()
                }
            }
        }
    }

    func stop() {
        if let m = monitor {
            NSEvent.removeMonitor(m)
            monitor = nil
        }
    }
}
