import Foundation

/// Parses output from `git status --porcelain=v2 --branch`.
///
/// Format reference:
/// - Branch headers: `# branch.oid <sha>`, `# branch.head <name>`,
///   `# branch.upstream <name>`, `# branch.ab +N -M`
/// - Ordinary changed entries: `1 XY ...`
/// - Renamed/copied entries: `2 XY ...`
/// - Untracked entries: `? <path>`
/// - Ignored entries: `! <path>`
public enum GitStatusParser {

    /// Parse the full output of `git status --porcelain=v2 --branch`.
    public static func parse(_ output: String) -> GitStatusInfo {
        var branch: String?
        var upstream: String?
        var ahead = 0
        var behind = 0
        var stagedCount = 0
        var modifiedCount = 0
        var untrackedCount = 0

        let lines = output.components(separatedBy: "\n")

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            if trimmed.hasPrefix("# branch.head ") {
                branch = String(trimmed.dropFirst("# branch.head ".count))
            } else if trimmed.hasPrefix("# branch.upstream ") {
                upstream = String(trimmed.dropFirst("# branch.upstream ".count))
            } else if trimmed.hasPrefix("# branch.ab ") {
                let abPart = String(trimmed.dropFirst("# branch.ab ".count))
                parseAheadBehind(abPart, ahead: &ahead, behind: &behind)
            } else if trimmed.hasPrefix("1 ") || trimmed.hasPrefix("2 ") {
                // Ordinary or rename/copy changed entry
                // Format: `1 XY ...` or `2 XY ...`
                // XY is the two-character status: X = index, Y = worktree
                parseChangedEntry(trimmed, staged: &stagedCount, modified: &modifiedCount)
            } else if trimmed.hasPrefix("u ") {
                // Unmerged entry — count as both staged and modified
                stagedCount += 1
                modifiedCount += 1
            } else if trimmed.hasPrefix("? ") {
                untrackedCount += 1
            }
            // Ignore `!` (ignored files) and `# branch.oid`
        }

        return GitStatusInfo(
            untrackedCount: untrackedCount,
            modifiedCount: modifiedCount,
            stagedCount: stagedCount,
            ahead: ahead,
            behind: behind,
            branch: branch,
            upstream: upstream
        )
    }

    // MARK: - Private

    /// Parse the `+N -M` part of `# branch.ab`.
    private static func parseAheadBehind(
        _ value: String,
        ahead: inout Int,
        behind: inout Int
    ) {
        let parts = value.split(separator: " ")
        for part in parts {
            if part.hasPrefix("+"), let n = Int(part.dropFirst()) {
                ahead = n
            } else if part.hasPrefix("-"), let n = Int(part.dropFirst()) {
                behind = n
            }
        }
    }

    /// Parse a changed entry line to determine if it has staged and/or unstaged changes.
    /// The XY status is at position 2-3 (after the type character and space).
    /// X = index status, Y = worktree status.
    /// `.` means no change; any other character means a change.
    private static func parseChangedEntry(
        _ line: String,
        staged: inout Int,
        modified: inout Int
    ) {
        // Line format: "1 XY ..." or "2 XY ..."
        // XY starts at index 2
        guard line.count >= 4 else { return }

        let startIndex = line.index(line.startIndex, offsetBy: 2)
        let x = line[startIndex]
        let y = line[line.index(after: startIndex)]

        if x != "." {
            staged += 1
        }
        if y != "." {
            modified += 1
        }
    }
}
