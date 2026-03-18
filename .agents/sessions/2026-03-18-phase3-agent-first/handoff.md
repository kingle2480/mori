# Handoff

<!-- Append a new phase section after each phase completes. -->

## Phase 1: Window Semantic Tags — COMPLETE

### Summary
Implemented window semantic tags (tasks 1.1-1.6) across 6 commits. Windows now carry a `WindowTag` enum describing their role (shell, editor, agent, server, logs, tests).

### What was done
1. **WindowTag enum** (`Packages/MoriCore/Sources/MoriCore/Models/WindowTag.swift`) — 6 cases with String raw values, SF Symbol mapping, and name-based inference heuristic.
2. **RuntimeWindow.tag** — Optional `WindowTag?` field added, default nil. Preserved across poll cycles.
3. **WindowBadge.longRunning** — New badge case mapping to `AlertState.warning`. StatusAggregator and WindowRowView updated.
4. **WindowTemplate.tag** — Templates carry explicit tags. TemplateRegistry updated: basic (shell/shell/logs), go (editor/server/tests/logs), agent (editor/agent/server/logs).
5. **Auto-assignment** — `WorkspaceManager.updateRuntimeState` and `refreshRuntimeState` infer tags from window names on first creation, preserve existing tags on subsequent polls.
6. **Sidebar + command palette** — WindowRowView icon reflects tag's SF Symbol. CommandPaletteItem.window carries tag in subtitle. `tag:<name>` prefix filtering in command palette search.
7. **Tests** — 55 new assertions (189 total MoriCore, 336 across all packages). Covers raw values, Codable, symbol names, inference, case-insensitivity, RuntimeWindow tag, longRunning badge, template tags.

### Files changed
- `Packages/MoriCore/Sources/MoriCore/Models/WindowTag.swift` (new)
- `Packages/MoriCore/Sources/MoriCore/Models/RuntimeWindow.swift`
- `Packages/MoriCore/Sources/MoriCore/Models/WindowBadge.swift`
- `Packages/MoriCore/Sources/MoriCore/Models/SessionTemplate.swift`
- `Packages/MoriCore/Sources/MoriCore/Models/TemplateRegistry.swift`
- `Packages/MoriCore/Sources/MoriCore/Models/StatusAggregator.swift`
- `Packages/MoriCore/Tests/MoriCoreTests/main.swift`
- `Packages/MoriUI/Sources/MoriUI/WindowRowView.swift`
- `Sources/Mori/App/WorkspaceManager.swift`
- `Sources/Mori/App/CommandPaletteItem.swift`
- `Sources/Mori/App/CommandPaletteDataSource.swift`
- `Sources/Mori/App/AppDelegate.swift`

### Build status
- Zero warnings under Swift 6 strict concurrency
- All 336 test assertions passing (189 core + 105 tmux + 42 persistence)

### Notes for next phase
- `WindowTag.infer(from:)` is in MoriCore, testable independently
- Tags are preserved across polls via `previousTags` lookup in WorkspaceManager
- The `tag:` prefix in command palette is case-insensitive and prefix-matches against tag raw values
- `WindowBadge.longRunning` is wired into StatusAggregator but not yet produced by any detection logic (that comes in Phase 2)

## Phase 2: Agent State Detection — COMPLETE

### Summary
Implemented agent state detection (tasks 2.1-2.7) across 7 commits. The coordinated poll now detects what's running in each pane, identifies agent states from output patterns, and assigns richer window badges.

### What was done
1. **TmuxPane extended** — Added `currentCommand` and `startTime` fields. TmuxParser pane format now includes `#{pane_current_command}` and `#{pane_start_time}`. Backward-compatible with shorter output.
2. **DetectedAgentState + PaneState** (`Packages/MoriTmux/Sources/MoriTmux/PaneState.swift`) — `DetectedAgentState` enum with String raw values mirroring MoriCore's `AgentState`. `PaneState` struct aggregates command, isRunning, isLongRunning, detectedAgentState, exitCode.
3. **PaneStateDetector** (`Packages/MoriTmux/Sources/MoriTmux/PaneStateDetector.swift`) — Static `detect(pane:capturedOutput:now:)` method. Pattern matching for waitingForInput (prompt suffixes `>`, `?`, `[Y/n]`, "Press any key", "waiting for input"), error (`error:`, `FAILED`, `panic:`, `fatal:`), completed (`Done`, `Complete`, `Finished`). Shell filtering (bash, zsh, fish, sh, -bash, -zsh). Long-running threshold 30s. Best-effort exit code parsing.
4. **capturePaneOutput** — Added to `TmuxControlling` protocol and `TmuxBackend`. Uses `tmux capture-pane -p -t <paneId> -S -<lineCount>`.
5. **Coordinated poll integration** — `WorkspaceManager.detectAgentStates` runs after tmux scan. Agent-tagged windows get full capture+detection. Non-agent windows derive running/idle from `currentCommand`. Maps `DetectedAgentState` to `AgentState`. Updates `RuntimeWindow.badge` and `Worktree.agentState`.
6. **Richer StatusAggregator** — New `windowBadge(hasUnreadOutput:isRunning:isLongRunning:agentState:)` with priority: error > waiting > longRunning > running > unread > idle.
7. **Tests** — 70 new tmux assertions (175 total), 8 new core assertions (197 total). Total: 414 across all packages.

### Files changed
- `Packages/MoriTmux/Sources/MoriTmux/TmuxPane.swift`
- `Packages/MoriTmux/Sources/MoriTmux/TmuxParser.swift`
- `Packages/MoriTmux/Sources/MoriTmux/PaneState.swift` (new)
- `Packages/MoriTmux/Sources/MoriTmux/PaneStateDetector.swift` (new)
- `Packages/MoriTmux/Sources/MoriTmux/TmuxBackend.swift`
- `Packages/MoriTmux/Sources/MoriTmux/TmuxControlling.swift`
- `Packages/MoriTmux/Tests/MoriTmuxTests/main.swift`
- `Packages/MoriCore/Sources/MoriCore/Models/StatusAggregator.swift`
- `Packages/MoriCore/Tests/MoriCoreTests/main.swift`
- `Sources/Mori/App/WorkspaceManager.swift`

### Build status
- Zero warnings under Swift 6 strict concurrency
- All 414 test assertions passing (197 core + 175 tmux + 42 persistence)

### Notes for next phase
- `PaneStateDetector.isShellProcess` and `longRunningThreshold` are public for use by WorkspaceManager
- `DetectedAgentState` raw values intentionally mirror `AgentState` for easy mapping; the separate type avoids MoriTmux depending on MoriCore
- Prompt suffix matching checks both raw line (with trailing space) and trimmed version (tmux may strip trailing whitespace)
- `Worktree.agentState` is updated with highest-priority agent state across its agent-tagged windows
- Phase 3 (Worktree Status Enhancements) should add `isRunning`, `isLongRunning`, `lastExitCode`, per-window `agentState` fields to `RuntimeWindow` and propagate from all panes, not just the active one
