import Foundation

/// Agent state detected from pane output patterns.
/// Local to MoriTmux — mirrors MoriCore's AgentState raw values for easy mapping.
public enum DetectedAgentState: String, Sendable, Equatable {
    case none
    case running
    case waitingForInput
    case error
    case completed
}

/// Aggregated state of a single tmux pane, derived from command info and captured output.
public struct PaneState: Sendable, Equatable {
    /// The command currently running in the pane (e.g. "node", "python", "zsh").
    public let command: String?
    /// Whether a non-shell command is actively running.
    public let isRunning: Bool
    /// Whether the running command has exceeded the long-running threshold (30s).
    public let isLongRunning: Bool
    /// Detected agent state from output pattern matching.
    public let detectedAgentState: DetectedAgentState
    /// Best-effort exit code parsed from captured output (e.g. "exit code: 1").
    public let exitCode: Int?

    public init(
        command: String? = nil,
        isRunning: Bool = false,
        isLongRunning: Bool = false,
        detectedAgentState: DetectedAgentState = .none,
        exitCode: Int? = nil
    ) {
        self.command = command
        self.isRunning = isRunning
        self.isLongRunning = isLongRunning
        self.detectedAgentState = detectedAgentState
        self.exitCode = exitCode
    }
}
