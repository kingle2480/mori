import SwiftUI
import MoriCore

/// Unified sidebar: all projects as flat sections, worktrees as two-line rows,
/// windows indented below, and action footer at the bottom.
public struct WorktreeSidebarView: View {
    private let projects: [Project]
    private let selectedProjectId: UUID?
    private let worktrees: [Worktree]
    private let windows: [RuntimeWindow]
    private let selectedWorktreeId: UUID?
    private let selectedWindowId: String?
    private let theme: TerminalTheme?
    private let onSelectProject: ((UUID) -> Void)?
    private let onSelectWorktree: (UUID) -> Void
    private let onSelectWindow: (String) -> Void
    private let onCreateWorktree: ((String) -> Void)?
    private let onRemoveWorktree: ((UUID) -> Void)?
    private let onAddProject: (() -> Void)?
    private let onOpenSettings: (() -> Void)?

    @State private var isCreatingWorktree = false
    @State private var newBranchName = ""
    @State private var isSubmitting = false

    public init(
        projects: [Project] = [],
        selectedProjectId: UUID? = nil,
        worktrees: [Worktree],
        windows: [RuntimeWindow],
        selectedWorktreeId: UUID?,
        selectedWindowId: String?,
        theme: TerminalTheme? = nil,
        onSelectProject: ((UUID) -> Void)? = nil,
        onSelectWorktree: @escaping (UUID) -> Void,
        onSelectWindow: @escaping (String) -> Void,
        onCreateWorktree: ((String) -> Void)? = nil,
        onRemoveWorktree: ((UUID) -> Void)? = nil,
        onAddProject: (() -> Void)? = nil,
        onOpenSettings: (() -> Void)? = nil
    ) {
        self.projects = projects
        self.selectedProjectId = selectedProjectId
        self.worktrees = worktrees
        self.windows = windows
        self.selectedWorktreeId = selectedWorktreeId
        self.selectedWindowId = selectedWindowId
        self.theme = theme
        self.onSelectProject = onSelectProject
        self.onSelectWorktree = onSelectWorktree
        self.onSelectWindow = onSelectWindow
        self.onCreateWorktree = onCreateWorktree
        self.onRemoveWorktree = onRemoveWorktree
        self.onAddProject = onAddProject
        self.onOpenSettings = onOpenSettings
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(projects) { project in
                        projectSection(project)
                    }
                }
                .padding(.top, MoriTokens.Spacing.lg)
            }

            Spacer(minLength: 0)

            sidebarFooter
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(sidebarBackground)
        .preferredColorScheme(theme.map { $0.isDark ? .dark : .light })
    }

    // MARK: - Project Section

    @ViewBuilder
    private func projectSection(_ project: Project) -> some View {
        // Section header
        HStack {
            Text(project.name)
                .font(MoriTokens.Font.sectionTitle)
                .foregroundStyle(MoriTokens.Color.muted)

            Spacer()

            if project.id == selectedProjectId, onCreateWorktree != nil {
                Button(action: {
                    onSelectProject?(project.id)
                    isCreatingWorktree = true
                    newBranchName = ""
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 11))
                        .foregroundStyle(MoriTokens.Color.muted)
                }
                .buttonStyle(.plain)
                .help("Create worktree")
            }
        }
        .padding(.horizontal, MoriTokens.Spacing.xl)
        .padding(.top, MoriTokens.Spacing.xl)
        .padding(.bottom, MoriTokens.Spacing.sm)
        .contentShape(Rectangle())
        .onTapGesture { onSelectProject?(project.id) }

        // Branch input (only for selected project)
        if project.id == selectedProjectId, isCreatingWorktree {
            branchNameInput
                .padding(.horizontal, MoriTokens.Spacing.sm)
        }

        // Worktrees for this project
        let projectWorktrees = worktrees.filter { $0.projectId == project.id }

        if projectWorktrees.isEmpty, project.id == selectedProjectId {
            Text("No worktrees")
                .font(MoriTokens.Font.caption)
                .foregroundStyle(MoriTokens.Color.muted)
                .padding(.horizontal, MoriTokens.Spacing.xl)
                .padding(.vertical, MoriTokens.Spacing.sm)
        }

        ForEach(projectWorktrees) { worktree in
            worktreeRow(worktree)
        }
    }

    // MARK: - Worktree Row

    @ViewBuilder
    private func worktreeRow(_ worktree: Worktree) -> some View {
        VStack(alignment: .leading, spacing: 0) {
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

            // Windows under selected worktree
            if worktree.id == selectedWorktreeId {
                let worktreeWindows = windows
                    .filter { $0.worktreeId == worktree.id }
                    .sorted { $0.tmuxWindowIndex < $1.tmuxWindowIndex }

                ForEach(worktreeWindows) { window in
                    WindowRowView(
                        window: window,
                        isActive: window.tmuxWindowId == selectedWindowId,
                        onSelect: { onSelectWindow(window.tmuxWindowId) }
                    )
                    .padding(.leading, MoriTokens.Spacing.xxl)
                }
            }
        }
        .padding(.horizontal, MoriTokens.Spacing.sm)
    }

    // MARK: - Branch Name Input

    private var branchNameInput: some View {
        HStack(spacing: MoriTokens.Spacing.sm) {
            if isSubmitting {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: "arrow.triangle.branch")
                    .font(MoriTokens.Font.label)
                    .foregroundStyle(MoriTokens.Color.muted)
            }

            TextField("Branch name", text: $newBranchName)
                .textFieldStyle(.plain)
                .font(.subheadline)
                .disabled(isSubmitting)
                .onSubmit { submitBranchName() }

            Button(action: { submitBranchName() }) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(MoriTokens.Color.success)
            }
            .buttonStyle(.plain)
            .disabled(newBranchName.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)

            Button(action: { cancelCreation() }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(MoriTokens.Color.muted)
            }
            .buttonStyle(.plain)
            .disabled(isSubmitting)
        }
        .padding(.horizontal, MoriTokens.Spacing.lg)
        .padding(.vertical, MoriTokens.Spacing.sm)
        .background(MoriTokens.Color.muted.opacity(MoriTokens.Opacity.subtle))
        .clipShape(RoundedRectangle(cornerRadius: MoriTokens.Radius.small))
    }

    private func submitBranchName() {
        let trimmed = newBranchName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !isSubmitting else { return }
        isSubmitting = true
        onCreateWorktree?(trimmed)
        isCreatingWorktree = false
        isSubmitting = false
        newBranchName = ""
    }

    private func cancelCreation() {
        isCreatingWorktree = false
        newBranchName = ""
    }

    // MARK: - Theme

    private var sidebarBackground: Color {
        if let theme {
            return Color(nsColor: nsColor(hex: theme.background))
        }
        return Color(nsColor: .controlBackgroundColor)
    }

    // MARK: - Footer

    private var sidebarFooter: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: MoriTokens.Spacing.lg) {
                if let onAddProject {
                    Button(action: onAddProject) {
                        HStack(spacing: MoriTokens.Spacing.sm) {
                            Image(systemName: "plus.rectangle.on.folder")
                                .font(.system(size: 12))
                            Text("Add Project")
                                .font(MoriTokens.Font.caption)
                        }
                        .foregroundStyle(MoriTokens.Color.muted)
                    }
                    .buttonStyle(.plain)
                    .help("Add Project")
                }

                Spacer()

                if let onOpenSettings {
                    Button(action: onOpenSettings) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 12))
                            .foregroundStyle(MoriTokens.Color.muted)
                    }
                    .buttonStyle(.plain)
                    .help("Settings (⌘,)")
                    .accessibilityLabel("Settings")
                }
            }
            .padding(.horizontal, MoriTokens.Spacing.xl)
            .padding(.vertical, MoriTokens.Spacing.lg)
        }
    }
}
