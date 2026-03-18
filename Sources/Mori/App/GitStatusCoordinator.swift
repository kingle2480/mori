import Foundation
import MoriCore
import MoriGit

/// Encapsulates git status polling logic.
/// Runs `gitBackend.status()` concurrently for all active worktrees via TaskGroup.
@MainActor
final class GitStatusCoordinator {

    let gitBackend: GitBackend

    init(gitBackend: GitBackend) {
        self.gitBackend = gitBackend
    }

    /// Poll git status for all active worktrees concurrently.
    /// Returns a map of worktreeId -> GitStatusInfo.
    /// Skips worktrees with status == .unavailable.
    func pollAll(worktrees: [Worktree]) async -> [UUID: GitStatusInfo] {
        let activeWorktrees = worktrees.filter { $0.status != .unavailable }
        guard !activeWorktrees.isEmpty else { return [:] }

        let backend = self.gitBackend
        return await withTaskGroup(of: (UUID, GitStatusInfo?).self) { group in
            for worktree in activeWorktrees {
                group.addTask {
                    do {
                        let status = try await backend.status(worktreePath: worktree.path)
                        return (worktree.id, status)
                    } catch {
                        return (worktree.id, nil)
                    }
                }
            }

            var results: [UUID: GitStatusInfo] = [:]
            for await (id, status) in group {
                if let status {
                    results[id] = status
                }
            }
            return results
        }
    }
}
