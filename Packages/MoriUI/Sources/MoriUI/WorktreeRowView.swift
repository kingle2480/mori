import SwiftUI
import MoriCore

/// A two-line row representing a single worktree: bold name + subtitle with status.
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
            HStack(alignment: .center, spacing: MoriTokens.Spacing.md) {
                Image(systemName: worktree.isMainWorktree ? "star.fill" : "arrow.triangle.branch")
                    .font(MoriTokens.Font.label)
                    .foregroundStyle(worktree.isMainWorktree ? MoriTokens.Color.attention : MoriTokens.Color.muted)

                VStack(alignment: .leading, spacing: MoriTokens.Spacing.xxs) {
                    HStack(spacing: MoriTokens.Spacing.sm) {
                        Text(worktree.branch ?? worktree.name)
                            .font(.system(.body, weight: .semibold))
                            .lineLimit(1)

                        gitStatusBadges
                    }

                    subtitleText
                }

                Spacer(minLength: 0)

                alertBadgeView
            }
            .padding(.vertical, MoriTokens.Spacing.md)
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

    // MARK: - Subtitle

    private var subtitleText: some View {
        HStack(spacing: MoriTokens.Spacing.sm) {
            Text(worktree.name)
                .font(MoriTokens.Font.caption)
                .foregroundStyle(MoriTokens.Color.muted)
                .lineLimit(1)

            if worktree.status == .active {
                Circle()
                    .fill(MoriTokens.Color.success)
                    .frame(width: MoriTokens.Icon.dot, height: MoriTokens.Icon.dot)
                    .accessibilityLabel("Active")
            }
        }
    }

    // MARK: - Git Status Badges

    @ViewBuilder
    private var gitStatusBadges: some View {
        HStack(spacing: MoriTokens.Spacing.xs) {
            if worktree.aheadCount > 0 || worktree.behindCount > 0 {
                HStack(spacing: MoriTokens.Spacing.xxs) {
                    if worktree.aheadCount > 0 {
                        Text("+\(worktree.aheadCount)")
                            .font(MoriTokens.Font.monoSmall)
                            .foregroundStyle(MoriTokens.Color.success)
                            .accessibilityLabel("\(worktree.aheadCount) ahead")
                    }
                    if worktree.behindCount > 0 {
                        Text("-\(worktree.behindCount)")
                            .font(MoriTokens.Font.monoSmall)
                            .foregroundStyle(MoriTokens.Color.error)
                            .accessibilityLabel("\(worktree.behindCount) behind")
                    }
                }
                .padding(.horizontal, MoriTokens.Spacing.sm)
                .padding(.vertical, MoriTokens.Spacing.xxs)
                .background(MoriTokens.Color.muted.opacity(MoriTokens.Opacity.subtle))
                .clipShape(RoundedRectangle(cornerRadius: MoriTokens.Radius.small))
            }

            if worktree.hasUncommittedChanges {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: MoriTokens.Icon.badge))
                    .foregroundStyle(MoriTokens.Color.warning)
                    .help("Uncommitted changes")
                    .accessibilityLabel("Uncommitted changes")
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
}
