# Remote UX + Config Open Plan

## Goals
- Fix `Open Ghostty Config` so it always opens as text and never executes in Terminal.
- Replace remote add form-sheet with a VS Code-style top input flow.
- Support both SSH key/agent and password auth for remote projects.

## Scope
1. Add top input remote wizard (host -> auth -> password(optional) -> path -> connect).
2. Integrate wizard with existing Add Project entry and command palette action.
3. Extend SSH config model and runners for endpoint auth metadata and SSH control options.
4. Add one-time SSH bootstrap for password mode so remote tmux/git polling works like local.
5. Normalize Ghostty config file permissions and force text-editor open behavior.

## Out of Scope
- Full SSH config profile manager.
- Persisting plaintext passwords.
- Multi-host orchestration UI.

## Acceptance Criteria
- Add Project can complete remote setup from top input flow.
- Password + key flows can both create a remote project successfully.
- Selecting remote worktree attaches and operates via remote tmux.
- Open config no longer launches shell output.
