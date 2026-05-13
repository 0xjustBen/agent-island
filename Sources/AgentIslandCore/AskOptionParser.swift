import Foundation

public struct AskOption: Hashable, Sendable {
    public let number: Int
    public let label: String
    public init(number: Int, label: String) { self.number = number; self.label = label }
}

public struct AskParseResult: Hashable, Sendable {
    public let question: String     // text before the options list
    public let options: [AskOption]
    public init(question: String, options: [AskOption]) {
        self.question = question; self.options = options
    }
}

public enum AskOptionParser {

    /// Line-anchored numbered list:   "1. foo"   or   "1) foo"
    private static let lineAnchored = try! NSRegularExpression(
        pattern: #"^\s*(\d+)[.)]\s+(.+?)\s*$"#, options: [.anchorsMatchLines]
    )

    /// Inline parenthesized options: "(1) Production (2) Staging (3) Local"
    /// Captures the number; label runs up to next `(N)` or end of string.
    private static let parenInline = try! NSRegularExpression(
        pattern: #"\((\d+)\)\s*([^()]+?)(?=\s*\(\d+\)|\s*$)"#, options: []
    )

    /// Parse a notification message looking for numbered options.
    /// Returns nil if fewer than 2 options found.
    public static func parse(_ message: String) -> AskParseResult? {
        let ns = message as NSString
        let range = NSRange(location: 0, length: ns.length)

        // Try line-anchored numbered first; fall back to inline parens.
        var matches = lineAnchored.matches(in: message, options: [], range: range)
        var useParen = false
        if matches.count < 2 {
            matches = parenInline.matches(in: message, options: [], range: range)
            useParen = true
        }
        guard matches.count >= 2 else { return nil }

        var options: [AskOption] = []
        for m in matches {
            let numStr = ns.substring(with: m.range(at: 1))
            let label = ns.substring(with: m.range(at: 2))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let n = Int(numStr), !label.isEmpty {
                options.append(AskOption(number: n, label: label))
            }
        }

        let firstMatchStart = matches.first!.range.location
        let questionRaw = ns.substring(with: NSRange(location: 0, length: firstMatchStart))
        let question = questionRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        _ = useParen
        return AskParseResult(question: question, options: options)
    }
}
