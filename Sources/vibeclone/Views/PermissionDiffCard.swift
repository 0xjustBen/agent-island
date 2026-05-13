import SwiftUI
import VibeCloneCore

struct PermissionDiffCard: View {
    let request: PermissionRequest
    let onApprove: () -> Void
    let onDeny: () -> Void
    var onAlwaysAllow: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.orange)
                Text("Permission needed")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.orange)
                Spacer()
            }
            HStack(spacing: 8) {
                Text(toolName)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 6).fill(.orange.opacity(0.18)))
                    .foregroundStyle(.orange)
                if let path = filePath {
                    Text(path)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(1).truncationMode(.middle)
                }
                Spacer()
            }
            if let plan = planText {
                ScrollView {
                    Text(MarkdownRenderer.render(plan))
                        .font(.system(size: 12))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.white)
                        .padding(10)
                }
                .frame(maxHeight: 220)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(white: 0.10)))
            } else if let lines = diffLines, !lines.isEmpty {
                diffBlock(lines)
                let (added, removed) = TextDiffer.stats(lines)
                Text("+\(added)  −\(removed)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.55))
            } else if let cmd = bashCommand {
                Text(cmd)
                    .font(.system(size: 12, design: .monospaced))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(white: 0.10)))
                    .foregroundStyle(.white)
            }
            if isDangerous {
                Text("⚠︎ Looks destructive — review carefully")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.red)
            }
            HStack(spacing: 8) {
                Button(action: onDeny) {
                    HStack(spacing: 6) {
                        cmdBadge("N", tint: .red)
                        Text("Deny").font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.10)))
                }
                .buttonStyle(.plain)
                .keyboardShortcut("n", modifiers: .command)

                Button(action: onApprove) {
                    HStack(spacing: 6) {
                        cmdBadge("Y", tint: .green)
                        Text("Approve").font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.green.opacity(0.30)))
                }
                .buttonStyle(.plain)
                .keyboardShortcut("y", modifiers: .command)
            }
            if let onAlwaysAllow, !isDangerous {
                Button(action: onAlwaysAllow) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.shield")
                            .font(.system(size: 10))
                        Text("Always allow \(toolName)")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(.cyan)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(.cyan.opacity(0.12)))
                }
                .buttonStyle(.plain)
                .help("Add \(toolName) to the auto-approve allow-list")
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.black))
    }

    private func cmdBadge(_ key: String, tint: Color) -> some View {
        HStack(spacing: 1) {
            Image(systemName: "command")
                .font(.system(size: 9, weight: .bold))
            Text(key)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 6).padding(.vertical, 3)
        .background(RoundedRectangle(cornerRadius: 5).fill(tint.opacity(0.20)))
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

    /// ExitPlanMode tool carries the agent's proposed plan in tool_input.plan.
    private var planText: String? {
        guard toolName == "ExitPlanMode",
              case .object(let input) = request.payload["tool_input"] ?? .null,
              case .string(let p) = input["plan"] ?? .null,
              !p.isEmpty else { return nil }
        return p
    }

    private var isDangerous: Bool {
        DangerousCommand.isDangerous(payload: request.payload)
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
