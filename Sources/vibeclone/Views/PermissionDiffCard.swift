import SwiftUI
import VibeCloneCore

struct PermissionDiffCard: View {
    let request: PermissionRequest
    let onApprove: () -> Void
    let onDeny: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Circle().fill(.orange).frame(width: 8, height: 8)
                Text("Permission Request")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                Text(toolName).font(.system(size: 14, weight: .bold)).foregroundStyle(.orange)
                if let path = filePath {
                    Text(path).font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                }
            }
            if let lines = diffLines, !lines.isEmpty {
                diffBlock(lines)
                let (added, removed) = TextDiffer.stats(lines)
                Text("+\(added) -\(removed)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.55))
            } else if let cmd = bashCommand {
                Text(cmd)
                    .font(.system(size: 12, design: .monospaced))
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 6).fill(.white.opacity(0.06)))
                    .foregroundStyle(.white.opacity(0.85))
            }
            HStack {
                Button("Deny ⌘N", role: .destructive, action: onDeny)
                    .buttonStyle(.bordered)
                    .keyboardShortcut("n", modifiers: .command)
                Spacer()
                Button("Allow ⌘Y", action: onApprove)
                    .buttonStyle(.borderedProminent).tint(.white)
                    .foregroundStyle(.black)
                    .keyboardShortcut("y", modifiers: .command)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(.black.opacity(0.6)))
    }

    private var toolName: String {
        if case .string(let s) = request.payload["tool_name"] ?? .null { return s }
        return "?"
    }

    private var filePath: String? {
        if case .object(let input) = request.payload["tool_input"] ?? .null,
           case .string(let p) = input["file_path"] ?? .null {
            return p
        }
        return nil
    }

    private var bashCommand: String? {
        if case .object(let input) = request.payload["tool_input"] ?? .null,
           case .string(let c) = input["command"] ?? .null {
            return c
        }
        return nil
    }

    private var diffLines: [DiffLine]? {
        guard case .object(let input) = request.payload["tool_input"] ?? .null else { return nil }
        switch toolName {
        case "Edit":
            if case .string(let old) = input["old_string"] ?? .null,
               case .string(let new) = input["new_string"] ?? .null {
                return TextDiffer.diff(old: old, new: new)
            }
        case "Write":
            if case .string(let content) = input["content"] ?? .null {
                return TextDiffer.diff(old: "", new: content)
            }
        default: break
        }
        return nil
    }

    @ViewBuilder
    private func diffBlock(_ lines: [DiffLine]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(lines.prefix(12).enumerated()), id: \.offset) { _, line in
                diffRow(line)
            }
            if lines.count > 12 {
                Text("…(\(lines.count - 12) more)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.horizontal, 6)
            }
        }
        .padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 6).fill(.black.opacity(0.4)))
    }

    @ViewBuilder
    private func diffRow(_ line: DiffLine) -> some View {
        let (prefix, text, color, bg): (String, String, Color, Color) = {
            switch line {
            case .context(let s): return (" ", s, .white.opacity(0.7), .clear)
            case .added(let s):   return ("+", s, .green, .green.opacity(0.12))
            case .removed(let s): return ("-", s, .red, .red.opacity(0.12))
            }
        }()
        HStack(spacing: 0) {
            Text(prefix)
                .font(.system(size: 12, design: .monospaced)).foregroundStyle(color)
                .frame(width: 12)
            Text(text)
                .font(.system(size: 12, design: .monospaced)).foregroundStyle(color)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 4).padding(.vertical, 1)
        .background(bg)
    }
}
