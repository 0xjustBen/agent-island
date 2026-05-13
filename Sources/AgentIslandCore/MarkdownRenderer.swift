import Foundation

public enum MarkdownRenderer {
    /// Render markdown source into an AttributedString suitable for SwiftUI Text.
    /// Uses inline-only parsing (no block-level structure) so it stays compact for
    /// previews — line breaks and whitespace are preserved.
    public static func render(_ source: String) -> AttributedString {
        let opts = AttributedString.MarkdownParsingOptions(
            allowsExtendedAttributes: false,
            interpretedSyntax: .inlineOnlyPreservingWhitespace
        )
        if let attr = try? AttributedString(markdown: source, options: opts) {
            return attr
        }
        return AttributedString(source)
    }

    /// Strip markdown markers — for short non-styled previews.
    public static func plain(_ source: String) -> String {
        var s = source
        s = s.replacingOccurrences(of: "**", with: "")
        s = s.replacingOccurrences(of: "__", with: "")
        s = s.replacingOccurrences(of: "*", with: "")
        s = s.replacingOccurrences(of: "_", with: "")
        s = s.replacingOccurrences(of: "`", with: "")
        s = s.replacingOccurrences(of: #"(?m)^#+\s+"#,
                                   with: "", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
