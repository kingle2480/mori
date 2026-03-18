import SwiftUI
import MoriCore

/// Sidebar showing worktrees as sections with their tmux windows as rows.
public struct WorktreeSidebarView: View {
    private let worktrees: [Worktree]
    private let windows: [RuntimeWindow]
    private let selectedWorktreeId: UUID?
    private let selectedWindowId: String?
    private let onSelectWorktree: (UUID) -> Void
    private let onSelectWindow: (String) -> Void

    public init(
        worktrees: [Worktree],
        windows: [RuntimeWindow],
        selectedWorktreeId: UUID?,
        selectedWindowId: String?,
        onSelectWorktree: @escaping (UUID) -> Void,
        onSelectWindow: @escaping (String) -> Void
    ) {
        self.worktrees = worktrees
        self.windows = windows
        self.selectedWorktreeId = selectedWorktreeId
        self.selectedWindowId = selectedWindowId
        self.onSelectWorktree = onSelectWorktree
        self.onSelectWindow = onSelectWindow
    }

    public var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 4) {
                if worktrees.isEmpty {
                    emptyState
                } else {
                    ForEach(worktrees) { worktree in
                        worktreeSection(worktree)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }

    // MARK: - Sections

    @ViewBuilder
    private func worktreeSection(_ worktree: Worktree) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            WorktreeRowView(
                worktree: worktree,
                isSelected: worktree.id == selectedWorktreeId,
                onSelect: { onSelectWorktree(worktree.id) }
            )

            let worktreeWindows = windows
                .filter { $0.worktreeId == worktree.id }
                .sorted { $0.tmuxWindowIndex < $1.tmuxWindowIndex }

            ForEach(worktreeWindows) { window in
                WindowRowView(
                    window: window,
                    isActive: window.tmuxWindowId == selectedWindowId,
                    onSelect: { onSelectWindow(window.tmuxWindowId) }
                )
                .padding(.leading, 16)
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "folder.badge.plus")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No worktrees")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 40)
    }
}
