import AppKit

/// Sends keystrokes via AppleScript "System Events". Requires Automation
/// permission for System Events (prompted on first call). Survives ad-hoc
/// codesign identity changes across debug rebuilds.
enum KeystrokeInjector {
    /// Type a number followed by Return.
    static func typeDigitsAndReturn(_ n: Int) {
        let script = """
        tell application "System Events"
            keystroke "\(n)"
            key code 36
        end tell
        """
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        let err = Pipe(); task.standardError = err; task.standardOutput = Pipe()
        do {
            try task.run()
            task.waitUntilExit()
            let data = err.fileHandleForReading.readDataToEndOfFile()
            if task.terminationStatus != 0, let s = String(data: data, encoding: .utf8) {
                NSLog("vibeclone: keystroke failed: \(s)")
            }
        } catch {
            NSLog("vibeclone: keystroke osascript launch failed: \(error)")
        }
    }
}
