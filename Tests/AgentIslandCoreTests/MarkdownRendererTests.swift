import Testing
import Foundation
@testable import AgentIslandCore

@Test func render_returns_attributed_string_for_simple_markdown() {
    let attr = MarkdownRenderer.render("**hello** world")
    let plain = String(attr.characters)
    #expect(plain.contains("hello"))
    #expect(plain.contains("world"))
    // Should NOT include literal markdown markers in rendered output.
    #expect(!plain.contains("**"))
}

@Test func render_falls_back_to_plain_on_garbage() {
    let attr = MarkdownRenderer.render("plain text no md")
    #expect(String(attr.characters) == "plain text no md")
}

@Test func plain_strips_bold_italic_code_headers() {
    #expect(MarkdownRenderer.plain("**bold**") == "bold")
    #expect(MarkdownRenderer.plain("__b__") == "b")
    #expect(MarkdownRenderer.plain("*it*") == "it")
    #expect(MarkdownRenderer.plain("_it_") == "it")
    #expect(MarkdownRenderer.plain("`code`") == "code")
    #expect(MarkdownRenderer.plain("# Title\nbody") == "Title\nbody")
    #expect(MarkdownRenderer.plain("## H2\nstuff") == "H2\nstuff")
}

@Test func plain_trims_whitespace() {
    #expect(MarkdownRenderer.plain("  \n\nhello\n\n  ") == "hello")
}
