import Foundation

/// Semantic tag for a tmux window, describing its role in a development workflow.
public enum WindowTag: String, Codable, Sendable, Equatable {
    case shell
    case editor
    case agent
    case server
    case logs
    case tests

    /// SF Symbol name for this tag.
    public var symbolName: String {
        switch self {
        case .shell: return "terminal"
        case .editor: return "pencil"
        case .agent: return "cpu"
        case .server: return "server.rack"
        case .logs: return "doc.text"
        case .tests: return "checkmark.circle"
        }
    }

    /// Infer a window tag from a window name using heuristic matching.
    public static func infer(from windowName: String) -> WindowTag {
        let lower = windowName.lowercased()
        if lower.contains("agent") { return .agent }
        if lower.contains("log") { return .logs }
        if lower.contains("server") { return .server }
        if lower.contains("editor") || lower.contains("edit") { return .editor }
        if lower.hasPrefix("test") || lower.contains("tests") { return .tests }
        return .shell
    }
}
