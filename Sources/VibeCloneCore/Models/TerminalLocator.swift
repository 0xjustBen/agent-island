import Foundation

public struct TerminalLocator: Codable, Hashable, Sendable {
    public let tty: String?
    public let cwd: String?
    public let ppid: Int32?
    public init(tty: String?, cwd: String?, ppid: Int32?) {
        self.tty = tty; self.cwd = cwd; self.ppid = ppid
    }
}
