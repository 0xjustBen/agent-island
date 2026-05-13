import AppKit
import Darwin

/// Sends keystrokes into a terminal session.
///
/// Strategy, in order:
/// 1. TIOCSTI ioctl on the target tty — no GUI permissions, works across
///    every terminal that shares our user, survives ad-hoc codesign rebuilds.
/// 2. AppleScript "System Events" keystroke — fallback for when we don't
///    have a tty path (jumper couldn't resolve, remote sessions, …).
enum KeystrokeInjector {
    static func typeDigitsAndReturn(_ n: Int, tty: String? = nil) {
        // Preferred: CGEvent.post — what every native mac tool uses
        // (Alfred, Raycast, Hammerspoon). Requires Accessibility permission;
        // stable across launches once the app codesign identity is stable.
        if AXIsProcessTrusted(), postCGEvent(digits: n) {
            NSLog("vibeclone: keystroke via CGEvent")
            return
        }
        // Fallback 1: TIOCSTI on the locator tty — no permission needed.
        let text = "\(n)\n"
        if let tty, !tty.isEmpty, writeViaTIOCSTI(tty: tty, text: text) {
            NSLog("vibeclone: keystroke via TIOCSTI on \(tty)")
            return
        }
        // Fallback 2: AppleScript System Events.
        NSLog("vibeclone: keystroke via osascript fallback")
        writeViaOSAScript(digits: n)
    }

    private static func postCGEvent(digits n: Int) -> Bool {
        // Virtual key codes for 0..9 on a US layout.
        let digitKey: [CGKeyCode] = [29, 18, 19, 20, 21, 23, 22, 26, 28, 25]
        let returnKey: CGKeyCode = 36
        let src = CGEventSource(stateID: .combinedSessionState)
        for ch in String(n) {
            guard let d = ch.hexDigitValue, (0...9).contains(d) else { return false }
            if !press(src, key: digitKey[d]) { return false }
        }
        if !press(src, key: returnKey) { return false }
        return true
    }

    private static func press(_ src: CGEventSource?, key: CGKeyCode) -> Bool {
        guard
            let down = CGEvent(keyboardEventSource: src, virtualKey: key, keyDown: true),
            let up   = CGEvent(keyboardEventSource: src, virtualKey: key, keyDown: false)
        else { return false }
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
        return true
    }

    /// Use TIOCSTI to push characters into a tty's input queue. Returns
    /// false on any failure so caller can fall back.
    private static func writeViaTIOCSTI(tty: String, text: String) -> Bool {
        let fd = open(tty, O_WRONLY | O_NOCTTY)
        guard fd >= 0 else { return false }
        defer { close(fd) }
        for byte in text.utf8 {
            var b = byte
            // TIOCSTI = 0x80017472 on macOS — push one char per ioctl call.
            if ioctl(fd, 0x80017472, &b) != 0 { return false }
        }
        return true
    }

    private static func writeViaOSAScript(digits n: Int) {
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
            try task.run(); task.waitUntilExit()
            let data = err.fileHandleForReading.readDataToEndOfFile()
            if task.terminationStatus != 0, let s = String(data: data, encoding: .utf8) {
                NSLog("vibeclone: osascript keystroke failed: \(s)")
            }
        } catch {
            NSLog("vibeclone: osascript launch failed: \(error)")
        }
    }
}
