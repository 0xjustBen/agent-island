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

    private static let numberedLine = try! NSRegularExpression(
        pattern: #"^\s*(\d+)[.)]\s+(.+?)\s*$"#, options: [.anchorsMatchLines]
    )

    /// Parse a notification message looking for numbered options.
    /// Returns nil if fewer than 2 options found.
    public static func parse(_ message: String) -> AskParseResult? {
        let ns = message as NSString
        let range = NSRange(location: 0, length: ns.length)
        let matches = numberedLine.matches(in: message, options: [], range: range)
        guard matches.count >= 2 else { return nil }
        var options: [AskOption] = []
        for m in matches {
            let numStr = ns.substring(with: m.range(at: 1))
            let label = ns.substring(with: m.range(at: 2))
            if let n = Int(numStr) {
                options.append(AskOption(number: n, label: label))
            }
        }
        // Question = lines before the first numbered match.
        let firstMatchStart = matches.first!.range.location
        let questionRaw = ns.substring(with: NSRange(location: 0, length: firstMatchStart))
        let question = questionRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        return AskParseResult(question: question, options: options)
    }
}
