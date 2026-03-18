import Foundation

/// Cursor display style in the terminal.
public enum CursorStyle: String, Codable, Sendable, CaseIterable {
    case block
    case underline
    case bar
}

/// Terminal appearance and behavior settings, persisted via UserDefaults.
public struct TerminalSettings: Codable, Equatable, Sendable {
    public var fontFamily: String
    public var fontSize: Double
    public var themeName: String
    public var cursorStyle: CursorStyle

    public init(
        fontFamily: String = "SF Mono",
        fontSize: Double = 13,
        themeName: String = TerminalTheme.defaultDark.name,
        cursorStyle: CursorStyle = .block
    ) {
        self.fontFamily = fontFamily
        self.fontSize = fontSize
        self.themeName = themeName
        self.cursorStyle = cursorStyle
    }

    /// Resolve the theme by name, falling back to Default Dark.
    public var theme: TerminalTheme {
        TerminalTheme.builtIn.first { $0.name == themeName } ?? .defaultDark
    }

    // MARK: - UserDefaults Persistence

    private static let defaultsKey = "terminalSettings"

    /// Stable suite so settings survive swift-run rebuilds (no bundle ID needed).
    nonisolated(unsafe) private static let defaults = UserDefaults(suiteName: "com.mori.app")!

    public static func load() -> TerminalSettings {
        guard let data = defaults.data(forKey: defaultsKey),
              let settings = try? JSONDecoder().decode(TerminalSettings.self, from: data)
        else {
            return TerminalSettings()
        }
        return settings
    }

    public func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        Self.defaults.set(data, forKey: Self.defaultsKey)
    }
}
