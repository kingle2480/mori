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
    private let onCreateWorktree: ((String) -> Void)?
    private let onRemoveWorktree: ((UUID) -> Void)?

    @State private var isCreatingWorktree = false
    @State private var newBranchName = ""

    public init(
        worktrees: [Worktree],
        windows: [RuntimeWindow],
        selectedWorktreeId: UUID?,
        selectedWindowId: String?,
        onSelectWorktree: @escaping (UUID) -> Void,
        onSelectWindow: @escaping (String) -> Void,
        onCreateWorktree: ((String) -> Void)? = nil,
        onRemoveWorktree: ((UUID) -> Void)? = nil
    ) {
        self.worktrees = worktrees
        self.windows = windows
        self.selectedWorktreeId = selectedWorktreeId
        self.selectedWindowId = selectedWindowId
        self.onSelectWorktree = onSelectWorktree
        self.onSelectWindow = onSelectWindow
        self.onCreateWorktree = onCreateWorktree
        self.onRemoveWorktree = onRemoveWorktree
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header with "+" button
            sidebarHeader

            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 4) {
                    if isCreatingWorktree {
                        branchNameInput
                    }
                    if worktrees.isEmpty && !isCreatingWorktree {
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }

    // MARK: - Header

    private var sidebarHeader: some View {
        HStack {
            Text("Worktrees")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Spacer()

            if onCreateWorktree != nil {
                Button(action: {
                    isCreatingWorktree = true
                    newBranchName = ""
                }) {
                    Image(systemName: "plus")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Create new worktree")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    // MARK: - Branch Name Input

    private var branchNameInput: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.triangle.branch")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("Branch name", text: $newBranchName)
                .textFieldStyle(.roundedBorder)
                .font(.subheadline)
                .onSubmit {
                    submitBranchName()
                }

            Button(action: { submitBranchName() }) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            .buttonStyle(.plain)
            .disabled(newBranchName.trimmingCharacters(in: .whitespaces).isEmpty)

            Button(action: { isCreatingWorktree = false }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private func submitBranchName() {
        let trimmed = newBranchName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        onCreateWorktree?(trimmed)
        isCreatingWorktree = false
        newBranchName = ""
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
            .contextMenu {
                if !worktree.isMainWorktree, let onRemove = onRemoveWorktree {
                    Button(role: .destructive) {
                        onRemove(worktree.id)
                    } label: {
                        Label("Remove Worktree...", systemImage: "trash")
                    }
                }
            }

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
