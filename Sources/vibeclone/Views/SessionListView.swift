import SwiftUI
import VibeCloneCore

struct SessionListView: View {
    @Bindable var controller: MenuBarController

    var body: some View {
        VStack(spacing: 6) {
            ForEach(controller.sessionCards, id: \.id) { card in
                VStack(spacing: 6) {
                    SessionCardView(card: card) {
                        controller.jumpToCard(card)
                    }
                    if let req = card.pendingPermission {
                        PermissionDiffCard(
                            request: req,
                            onApprove: { controller.approve(req) },
                            onDeny:    { controller.deny(req) }
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
    }
}
