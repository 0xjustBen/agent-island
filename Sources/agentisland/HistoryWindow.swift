import AppKit
import SwiftUI
import AgentIslandCore

@MainActor
final class HistoryWindow {
    private var window: NSWindow?
    private let paths: Paths

    init(paths: Paths) { self.paths = paths }

    func show() {
        if window == nil { build() }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func build() {
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false
        )
        w.title = "AgentIsland History"
        w.center()
        w.isReleasedWhenClosed = false
        w.contentView = NSHostingView(rootView: HistoryView(paths: paths))
        self.window = w
    }
}

private struct HistoryEntry: Identifiable, Hashable {
    let id: String
    let ts: String
    let source: String
    let event: String
    let decision: String
    let cwd: String
}

struct HistoryView: View {
    let paths: Paths
    @State private var entries: [HistoryEntry] = []
    @State private var filter: String = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Filter (source, event, cwd)", text: $filter)
                    .textFieldStyle(.plain)
                Button { load() } label: { Image(systemName: "arrow.clockwise") }
                    .buttonStyle(.plain)
                    .help("Reload")
            }
            .padding(8)
            .background(.bar)
            Divider()
            Table(filtered) {
                TableColumn("Time") { Text($0.ts).font(.system(.caption, design: .monospaced)) }
                    .width(min: 140, ideal: 160)
                TableColumn("Source") { Text($0.source) }.width(min: 60, ideal: 80)
                TableColumn("Event") { Text($0.event) }.width(min: 100, ideal: 140)
                TableColumn("Decision") {
                    Text($0.decision)
                        .foregroundStyle($0.decision == "approve" ? .green :
                                        $0.decision == "deny" ? .red : .secondary)
                }
                .width(min: 70, ideal: 90)
                TableColumn("CWD") { Text($0.cwd).font(.system(.caption, design: .monospaced)) }
            }
        }
        .onAppear(perform: load)
    }

    private var filtered: [HistoryEntry] {
        guard !filter.isEmpty else { return entries }
        let q = filter.lowercased()
        return entries.filter {
            $0.source.lowercased().contains(q)
                || $0.event.lowercased().contains(q)
                || $0.cwd.lowercased().contains(q)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: paths.historyJSONL),
              let text = String(data: data, encoding: .utf8) else {
            entries = []; return
        }
        let lines = text.split(whereSeparator: \.isNewline).suffix(2000)
        var out: [HistoryEntry] = []
        for line in lines {
            guard let d = line.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: d) as? [String: Any] else { continue }
            out.append(HistoryEntry(
                id: (obj["id"] as? String) ?? UUID().uuidString,
                ts: (obj["ts"] as? String) ?? "",
                source: (obj["source"] as? String) ?? "",
                event: (obj["event"] as? String) ?? "",
                decision: (obj["decision"] as? String) ?? "",
                cwd: (obj["cwd"] as? String) ?? ""
            ))
        }
        entries = out.reversed()  // newest first
    }
}
