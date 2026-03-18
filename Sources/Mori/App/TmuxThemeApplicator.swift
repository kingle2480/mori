import MoriCore
import MoriTmux

/// Applies terminal theme colors to tmux so that tmux's own rendering
/// (pane background, status bar, borders) matches the selected theme.
///
/// Sets both global defaults (for new sessions) and per-session overrides
/// (for existing sessions). Then refreshes every connected client so
/// changes take effect immediately.
enum TmuxThemeApplicator {

    static func apply(settings: TerminalSettings, tmuxBackend: TmuxBackend) async {
        let theme = settings.theme
        let fg = hexColor(theme.foreground)
        let bg = hexColor(theme.background)

        let windowStyle = "fg=\(fg),bg=\(bg)"
        let borderFg = hexColor(theme.ansi[8])      // bright black
        let activeBorderFg = hexColor(theme.ansi[4]) // blue
        let statusBg = hexColor(theme.ansi[0])       // palette black

        // Session-level options (set-option -g)
        let sessionOptions: [(String, String)] = [
            ("status", "off"),
            ("status-style", "fg=\(fg),bg=\(statusBg)"),
            ("message-style", "fg=\(fg),bg=\(statusBg)"),
        ]

        // Window-level options (set-option -gw)
        let windowOptions: [(String, String)] = [
            ("window-style", windowStyle),
            ("window-active-style", windowStyle),
            ("pane-border-style", "fg=\(borderFg)"),
            ("pane-active-border-style", "fg=\(activeBorderFg)"),
        ]

        // Apply global session options
        for (option, value) in sessionOptions {
            do {
                try await tmuxBackend.setOption(sessionId: nil, option: option, value: value)
            } catch {
                print("[TmuxThemeApplicator] Failed to set global session option \(option): \(error)")
            }
        }

        // Apply global window options (-gw flag)
        for (option, value) in windowOptions {
            do {
                try await tmuxBackend.setWindowOption(global: true, target: nil, option: option, value: value)
            } catch {
                print("[TmuxThemeApplicator] Failed to set global window option \(option): \(error)")
            }
        }

        // Also apply to all existing sessions so they pick up the change immediately
        do {
            let sessions = try await tmuxBackend.scanAll()
            for session in sessions {
                for (option, value) in sessionOptions {
                    try? await tmuxBackend.setOption(sessionId: session.id, option: option, value: value)
                }
                for (option, value) in windowOptions {
                    try? await tmuxBackend.setWindowOption(global: false, target: session.id, option: option, value: value)
                }
            }
        } catch {
            print("[TmuxThemeApplicator] Failed to list sessions for per-session theme: \(error)")
        }

        // Force all attached clients to redraw
        do {
            try await tmuxBackend.refreshClients()
        } catch {
            print("[TmuxThemeApplicator] Failed to refresh clients: \(error)")
        }
    }

    private static func hexColor(_ hex: String) -> String {
        let stripped = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        return "#\(stripped)"
    }
}
