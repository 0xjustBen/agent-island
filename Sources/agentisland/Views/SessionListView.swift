import SwiftUI
import AgentIslandCore

struct SessionListView: View {
    @Bindable var controller: MenuBarController
    @State private var selectedIndex: Int = 0
    @State private var sourceFilter: String? = nil
    @State private var projectFilter: String? = nil

    private var visibleCards: [SessionCard] {
        controller.sessionCards.filter { card in
            (sourceFilter.map { $0 == card.source } ?? true)
            && (projectFilter.map { $0 == projectName(card) } ?? true)
        }
    }

    private func projectName(_ c: SessionCard) -> String {
        URL(fileURLWithPath: c.lastLocator.cwd ?? "/").lastPathComponent
    }

    private func toolName(_ r: PermissionRequest) -> String {
        if case .string(let s) = r.payload["tool_name"] ?? .null { return s }
        return ""
    }

    var body: some View {
        VStack(spacing: 6) {
            filterChips
            ForEach(Array(visibleCards.enumerated()), id: \.element.id) { idx, card in
                VStack(spacing: 6) {
                    SessionCardView(card: card) {
                        controller.jumpToCard(card)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(idx == selectedIndex ? Color.cyan.opacity(0.7) : .clear,
                                    lineWidth: 1.5)
                    )
                    if let req = card.pendingPermission {
                        PermissionDiffCard(
                            request: req,
                            onApprove: { controller.approve(req) },
                            onDeny:    { controller.deny(req) },
                            onAlwaysAllow: {
                                controller.alwaysAllow(tool: toolName(req))
                                controller.approve(req)
                            }
                        )
                    }
                    if let notice = card.pendingNotice {
                        AskCard(
                            card: card,
                            notice: notice,
                            parsed: AskOptionParser.parse(notice.message),
                            onPick: { opt in controller.pickAskOption(card: card, option: opt) },
                            onDismiss: { controller.dismissNotice(notice) }
                        )
                    }
                }
            }
            if controller.sessionCards.isEmpty {
                Text("No active sessions").font(.caption).foregroundStyle(.white.opacity(0.5))
                    .padding(.vertical, 8)
            }
        }
        .background(
            // Invisible hot-keys for arrow nav + Return-to-jump.
            VStack {
                Button("") { moveSelection(-1) }
                    .keyboardShortcut(.upArrow, modifiers: [])
                Button("") { moveSelection( 1) }
                    .keyboardShortcut(.downArrow, modifiers: [])
                Button("") {
                    let cards = controller.sessionCards
                    guard !cards.isEmpty else { return }
                    let i = max(0, min(selectedIndex, cards.count - 1))
                    controller.jumpToCard(cards[i])
                }
                .keyboardShortcut(.return, modifiers: [])
            }
            .opacity(0).frame(width: 0, height: 0)
        )
    }

    private func moveSelection(_ delta: Int) {
        let cards = visibleCards
        guard !cards.isEmpty else { return }
        selectedIndex = (selectedIndex + delta + cards.count) % cards.count
    }

    @ViewBuilder
    private var filterChips: some View {
        let sources = Array(Set(controller.sessionCards.map(\.source))).sorted()
        let projects = Array(Set(controller.sessionCards.map(projectName))).sorted()
        if sources.count > 1 || projects.count > 1 {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    chip(label: "All", active: sourceFilter == nil && projectFilter == nil) {
                        sourceFilter = nil; projectFilter = nil
                    }
                    if sources.count > 1 {
                        ForEach(sources, id: \.self) { src in
                            chip(label: AgentBranding.brand(for: src).displayName,
                                 active: sourceFilter == src) {
                                sourceFilter = (sourceFilter == src) ? nil : src
                            }
                        }
                    }
                    if projects.count > 1 {
                        ForEach(projects, id: \.self) { proj in
                            chip(label: proj, active: projectFilter == proj) {
                                projectFilter = (projectFilter == proj) ? nil : proj
                            }
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private func chip(label: String, active: Bool, tap: @escaping () -> Void) -> some View {
        Button(action: tap) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Capsule().fill(active ? .cyan.opacity(0.30) : .white.opacity(0.10)))
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }
}
