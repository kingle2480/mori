import SwiftUI
import MoriCore

/// A row representing a single worktree, displayed as a section header.
public struct WorktreeRowView: View {
    let worktree: Worktree
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovered = false

    public init(
        worktree: Worktree,
        isSelected: Bool,
        onSelect: @escaping () -> Void
    ) {
        self.worktree = worktree
        self.isSelected = isSelected
        self.onSelect = onSelect
    }

    public var body: some View {
        Button(action: onSelect) {
            HStack(spacing: MoriTokens.Spacing.md) {
                Image(systemName: "arrow.triangle.branch")
                    .font(MoriTokens.Font.label)
                    .foregroundStyle(MoriTokens.Color.muted)

                Text(worktree.branch ?? worktree.name)
                    .font(MoriTokens.Font.rowTitle)
                    .lineLimit(1)

                Spacer()

                gitStatusBadges

                alertBadgeView

                statusIndicator
            }
            .padding(.vertical, MoriTokens.Spacing.sm)
            .padding(.horizontal, MoriTokens.Spacing.lg)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: MoriTokens.Radius.small))
        .onHover { isHovered = $0 }
    }

    private var rowBackground: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(MoriTokens.Color.active.opacity(MoriTokens.Opacity.light))
        } else if isHovered {
            return AnyShapeStyle(MoriTokens.Color.muted.opacity(MoriTokens.Opacity.subtle))
        } else {
            return AnyShapeStyle(Color.clear)
        }
    }

    // MARK: - Git Status Badges

    @ViewBuilder
    private var gitStatusBadges: some View {
        HStack(spacing: MoriTokens.Spacing.sm) {
            if worktree.hasUncommittedChanges {
                Circle()
                    .fill(MoriTokens.Color.warning)
                    .frame(width: MoriTokens.Icon.dot, height: MoriTokens.Icon.dot)
                    .help("Uncommitted changes")
                    .accessibilityLabel("Uncommitted changes")
            }

            if worktree.aheadCount > 0 {
                HStack(spacing: MoriTokens.Spacing.xxs) {
                    Image(systemName: "arrow.up")
                        .font(MoriTokens.Font.arrowIcon)
                    Text("\(worktree.aheadCount)")
                        .font(MoriTokens.Font.monoSmall)
                }
                .foregroundStyle(MoriTokens.Color.success)
                .help("\(worktree.aheadCount) ahead of upstream")
                .accessibilityLabel("\(worktree.aheadCount) ahead of upstream")
            }

            if worktree.behindCount > 0 {
                HStack(spacing: MoriTokens.Spacing.xxs) {
                    Image(systemName: "arrow.down")
                        .font(MoriTokens.Font.arrowIcon)
                    Text("\(worktree.behindCount)")
                        .font(MoriTokens.Font.monoSmall)
                }
                .foregroundStyle(MoriTokens.Color.error)
                .help("\(worktree.behindCount) behind upstream")
                .accessibilityLabel("\(worktree.behindCount) behind upstream")
            }

            if worktree.unreadCount > 0 {
                Text("\(worktree.unreadCount)")
                    .font(MoriTokens.Font.badgeCount)
                    .foregroundStyle(.white)
                    .padding(.horizontal, MoriTokens.Spacing.sm)
                    .padding(.vertical, MoriTokens.Spacing.xxs)
                    .background(Capsule().fill(MoriTokens.Color.info))
                    .help("\(worktree.unreadCount) unread")
                    .accessibilityLabel("\(worktree.unreadCount) unread")
            }
        }
    }

    // MARK: - Alert Badge

    @ViewBuilder
    private var alertBadgeView: some View {
        switch worktree.agentState {
        case .error:
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: MoriTokens.Icon.badge))
                .foregroundStyle(MoriTokens.Color.error)
                .help("Agent error")
                .accessibilityLabel("Agent error")
        case .waitingForInput:
            Image(systemName: "exclamationmark.bubble.fill")
                .font(.system(size: MoriTokens.Icon.badge))
                .foregroundStyle(MoriTokens.Color.attention)
                .help("Agent waiting for input")
                .accessibilityLabel("Agent waiting for input")
        case .running:
            Image(systemName: "bolt.fill")
                .font(.system(size: MoriTokens.Icon.badge))
                .foregroundStyle(MoriTokens.Color.success)
                .help("Agent running")
                .accessibilityLabel("Agent running")
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: MoriTokens.Icon.badge))
                .foregroundStyle(MoriTokens.Color.success)
                .help("Agent completed")
                .accessibilityLabel("Agent completed")
        case .none:
            EmptyView()
        }
    }

    // MARK: - Status Indicator

    @ViewBuilder
    private var statusIndicator: some View {
        switch worktree.status {
        case .active:
            Circle()
                .fill(MoriTokens.Color.success)
                .frame(width: MoriTokens.Icon.indicator, height: MoriTokens.Icon.indicator)
                .accessibilityLabel("Active")
        case .inactive:
            Circle()
                .fill(MoriTokens.Color.inactive)
                .frame(width: MoriTokens.Icon.indicator, height: MoriTokens.Icon.indicator)
                .accessibilityLabel("Inactive")
        case .unavailable:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(MoriTokens.Font.caption)
                .foregroundStyle(MoriTokens.Color.warning)
                .accessibilityLabel("Unavailable")
        }
    }
}
