import SwiftUI
import MoriCore

/// A row representing a single worktree, displayed as a section header.
public struct WorktreeRowView: View {
    let worktree: Worktree
    let isSelected: Bool
    let onSelect: () -> Void

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
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(worktree.branch ?? worktree.name)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                statusIndicator
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    @ViewBuilder
    private var statusIndicator: some View {
        switch worktree.status {
        case .active:
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
        case .inactive:
            Circle()
                .fill(Color.gray)
                .frame(width: 8, height: 8)
        case .unavailable:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption2)
                .foregroundStyle(.orange)
        }
    }
}
