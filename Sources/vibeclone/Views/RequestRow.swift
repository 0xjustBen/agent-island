import SwiftUI
import VibeCloneCore

struct RequestRow: View {
    let request: PermissionRequest
    let onApprove: () -> Void
    let onDeny: () -> Void
    let onJump: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "terminal")
                Text(request.source).bold()
                Text("•").foregroundStyle(.secondary)
                Text(toolName).font(.system(.body, design: .monospaced))
                Spacer()
                if let cwd = request.locator.cwd {
                    Text(URL(fileURLWithPath: cwd).lastPathComponent)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            inputPreview
            planPreview
            HStack {
                Button("Jump", action: onJump)
                Spacer()
                Button("Deny", role: .destructive, action: onDeny)
                Button("Approve", action: onApprove)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(.background.secondary))
    }

    private var toolName: String {
        if case .string(let s) = request.payload["tool_name"] ?? .null { return s }
        return "?"
    }

    @ViewBuilder private var inputPreview: some View {
        ScrollView(.horizontal) {
            Text(previewText)
                .font(.system(.callout, design: .monospaced))
                .lineLimit(4)
                .padding(6)
        }
        .frame(maxHeight: 100)
        .background(RoundedRectangle(cornerRadius: 4).fill(.black.opacity(0.06)))
    }

    @ViewBuilder private var planPreview: some View {
        if let md = planSource {
            DisclosureGroup("Plan preview") {
                Text(MarkdownRenderer.render(md))
                    .font(.callout)
                    .padding(.vertical, 4)
            }
        }
    }

    private var planSource: String? {
        // Plan-mode CC payloads include the assistant's plan text. Heuristic:
        // tool_input.plan, tool_input.prompt, or payload.plan as a long string.
        if case .object(let input) = request.payload["tool_input"] ?? .null {
            if case .string(let s) = input["plan"] ?? .null, s.count > 20 { return s }
            if case .string(let s) = input["prompt"] ?? .null, s.count > 60 { return s }
        }
        if case .string(let s) = request.payload["plan"] ?? .null, s.count > 20 { return s }
        return nil
    }

    private var previewText: String {
        // Prefer tool_input.command for Bash; otherwise pretty-print tool_input.
        if case .object(let input) = request.payload["tool_input"] ?? .null,
           case .string(let cmd) = input["command"] ?? .null {
            return cmd
        }
        if case .object(let input) = request.payload["tool_input"] ?? .null,
           let data = try? JSONSerialization.data(
            withJSONObject: JSONValueWire.unwrap(.object(input)),
            options: [.prettyPrinted]),
           let s = String(data: data, encoding: .utf8) {
            return s
        }
        return "(no preview)"
    }
}
