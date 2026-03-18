import Foundation

/// Built-in session templates for common development workflows.
public enum TemplateRegistry {

    /// Basic template: shell, run, logs.
    public static let basic = SessionTemplate(
        name: "basic",
        windows: [
            WindowTemplate(name: "shell", tag: .shell),
            WindowTemplate(name: "run", tag: .shell),
            WindowTemplate(name: "logs", tag: .logs),
        ]
    )

    /// Go template: editor, server, tests, logs.
    public static let go = SessionTemplate(
        name: "go",
        windows: [
            WindowTemplate(name: "editor", tag: .editor),
            WindowTemplate(name: "server", command: "go run .", tag: .server),
            WindowTemplate(name: "tests", command: "go test ./...", tag: .tests),
            WindowTemplate(name: "logs", tag: .logs),
        ]
    )

    /// Agent template: editor, agent, server, logs.
    public static let agent = SessionTemplate(
        name: "agent",
        windows: [
            WindowTemplate(name: "editor", tag: .editor),
            WindowTemplate(name: "agent", tag: .agent),
            WindowTemplate(name: "server", tag: .server),
            WindowTemplate(name: "logs", tag: .logs),
        ]
    )

    /// All built-in templates.
    public static let all: [SessionTemplate] = [basic, go, agent]

    /// Look up a template by name. Returns `basic` if not found.
    public static func template(named name: String) -> SessionTemplate {
        all.first { $0.name == name } ?? basic
    }
}
