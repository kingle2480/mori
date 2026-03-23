# Implementation Notes

## UI
- New `RemoteConnectWizardController` provides top-panel step flow:
  - Host: `[user@]host[:port]`
  - Auth: key/agent or password
  - Password (secure, if selected)
  - Remote repo path
  - Connecting status + inline errors

## App Wiring
- `AppDelegate`:
  - Add entrypoint `showRemoteConnectWizard()`.
  - Route Add Project -> Remote option to wizard.
  - Add command palette action `Remote: Connect to Host...`.
  - Update settings action to open config explicitly in TextEdit.

## Remote Transport
- Extend `SSHWorkspaceLocation` with auth mode metadata.
- Extend `GitSSHConfig` and `TmuxSSHConfig` to pass extra ssh options.
- WorkspaceManager computes endpoint control options and injects into runners.
- Password mode uses one-time bootstrap via `SSHBootstrapper` to establish ControlMaster socket.

## Config Open Fix
- Add helpers in `GhosttyConfigFile` to ensure file exists and remove executable bits.
- Use explicit editor open instead of generic `NSWorkspace.open(url)`.

## Validation
- `mise run build`
- `mise run build:release`
- `mise run test`
