import AppKit
import MoriCore
import SwiftTerm

/// Terminal adapter backed by SwiftTerm — a full VT100/xterm emulator.
/// Provides cursor rendering, colors, mouse support, and proper tmux compatibility.
@MainActor
public final class SwiftTermAdapter: TerminalHost {

    public var settings: TerminalSettings {
        didSet {
            if settings != oldValue {
                settings.save()
            }
        }
    }

    public init(settings: TerminalSettings = .load()) {
        self.settings = settings
        TerminalScrollFix.install()
        TerminalPasteFix.install()
    }

    public func createSurface(command: String, workingDirectory: String) -> NSView {
        let termView = LocalProcessTerminalView(frame: .zero)
        configureTerminalView(termView)

        let shell = "/bin/zsh"
        let args = ["-l", "-c", command]
        let env = processEnvironment()

        termView.startProcess(
            executable: shell,
            args: args,
            environment: env,
            execName: shell,
            currentDirectory: workingDirectory
        )

        return termView
    }

    public func destroySurface(_ surface: NSView) {
        guard let termView = surface as? LocalProcessTerminalView else { return }
        let terminal = termView.getTerminal()
        terminal.sendResponse(text: "\u{04}")  // Ctrl+D / EOF
    }

    public func surfaceDidResize(_ surface: NSView, to size: NSSize) {
        // SwiftTerm handles resize automatically via NSView layout
    }

    public func focusSurface(_ surface: NSView) {
        surface.window?.makeFirstResponder(surface)
    }

    /// Apply current settings to an existing terminal surface.
    /// Font and cursor changes apply immediately. Theme colors are set on SwiftTerm
    /// but tmux overrides them via its own escape sequences — so we also send a
    /// SIGWINCH-style resize event to force tmux to redraw with its updated options.
    public func applySettings(to surface: NSView) {
        guard let termView = surface as? LocalProcessTerminalView else { return }
        configureTerminalView(termView)

        // Force tmux to redraw by sending a window-change signal through the PTY.
        // SwiftTerm's resize path sends SIGWINCH to the child process, which
        // causes tmux to re-render using its (now updated) color options.
        let currentSize = termView.frame.size
        if currentSize.width > 1, currentSize.height > 1 {
            let nudged = NSSize(width: currentSize.width - 1, height: currentSize.height)
            termView.setFrameSize(nudged)
            termView.setFrameSize(currentSize)
        }
    }

    // MARK: - Private

    private func configureTerminalView(_ termView: LocalProcessTerminalView) {
        // Font
        let font = resolveFont()
        termView.font = font

        // Theme colors — set fg/bg/caret/selection before installColors,
        // because installColors triggers a full redraw via colorsChanged().
        let theme = settings.theme
        termView.nativeForegroundColor = NSColor(hex: theme.foreground)
        termView.nativeBackgroundColor = NSColor(hex: theme.background)
        termView.caretColor = NSColor(hex: theme.cursor)
        termView.selectedTextBackgroundColor = NSColor(hex: theme.selection)

        // ANSI palette — installColors calls colorsChanged() which flushes
        // the color cache and triggers a full display refresh.
        let ansiColors = theme.ansi.map { swiftTermColor(hex: $0) }
        if ansiColors.count == 16 {
            termView.installColors(ansiColors)
        }

        // Force layer background update (SwiftTerm doesn't sync this automatically)
        termView.layer?.backgroundColor = NSColor(hex: theme.background).cgColor
        termView.needsDisplay = true

        // Cursor style
        let terminal = termView.getTerminal()
        switch settings.cursorStyle {
        case .block:
            terminal.setCursorStyle(.blinkBlock)
        case .underline:
            terminal.setCursorStyle(.blinkUnderline)
        case .bar:
            terminal.setCursorStyle(.blinkBar)
        }
    }

    private func resolveFont() -> NSFont {
        let size = CGFloat(settings.fontSize)

        // Try the user-specified family first
        if let font = NSFont(name: settings.fontFamily, size: size) {
            return font
        }

        // Try common monospace font name variations
        let variations = [
            settings.fontFamily + "-Regular",
            settings.fontFamily.replacingOccurrences(of: " ", with: ""),
            settings.fontFamily.replacingOccurrences(of: " ", with: "-"),
        ]
        for name in variations {
            if let font = NSFont(name: name, size: size) {
                return font
            }
        }

        // Fallback to system monospace
        return NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
    }

    private func processEnvironment() -> [String] {
        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "xterm-256color"
        env["LANG"] = "en_US.UTF-8"
        env["HOME"] = env["HOME"] ?? NSHomeDirectory()
        return env.map { "\($0.key)=\($0.value)" }
    }
}

// MARK: - Terminal Scroll Fix

/// Installs a local event monitor that intercepts scroll-wheel events
/// targeting a `LocalProcessTerminalView` and forwards them to the PTY
/// as mouse button 4/5 escape sequences when tmux mouse mode is active.
///
/// SwiftTerm's built-in `scrollWheel` always scrolls the internal buffer
/// but never sends mouse escape sequences, so tmux `mouse on` scrolling
/// doesn't work without this.
@MainActor
enum TerminalScrollFix {
    private static var monitor: Any?

    static func install() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            guard event.deltaY != 0,
                  let terminalView = findTerminalView(for: event)
            else {
                return event
            }

            let terminal = terminalView.getTerminal()
            let mode = terminal.mouseMode

            // Only intercept when mouse mode is active (mirrors sendButtonPress logic).
            guard mode == .vt200 || mode == .buttonEventTracking || mode == .anyEvent else {
                return event
            }

            // Compute grid position from font metrics (cellDimension is internal).
            let f = terminalView.font
            let cellWidth = max(f.maximumAdvancement.width, 1)
            let cellHeight = max(f.ascender - f.descender + f.leading, 1)

            let point = terminalView.convert(event.locationInWindow, from: nil)
            let col = min(max(0, Int(point.x / cellWidth)), terminal.cols - 1)
            let row = min(max(0, Int((terminalView.frame.height - point.y) / cellHeight)), terminal.rows - 1)

            let flags = event.modifierFlags
            let button = event.deltaY > 0 ? 4 : 5
            let lines = max(1, Int(abs(event.deltaY)))
            let pixelX = Int(point.x)
            let pixelY = Int(terminalView.frame.height - point.y)

            for _ in 0..<lines {
                let buttonFlags = terminal.encodeButton(
                    button: button,
                    release: false,
                    shift: flags.contains(.shift),
                    meta: flags.contains(.option),
                    control: flags.contains(.control)
                )
                terminal.sendEvent(
                    buttonFlags: buttonFlags,
                    x: col,
                    y: row,
                    pixelX: pixelX,
                    pixelY: pixelY
                )
            }

            // Consume the event so SwiftTerm doesn't also buffer-scroll.
            return nil
        }
    }

    private static func findTerminalView(for event: NSEvent) -> LocalProcessTerminalView? {
        guard let window = event.window else { return nil }
        let point = event.locationInWindow
        guard let hitView = window.contentView?.hitTest(point) else { return nil }
        // Walk up the view hierarchy to find the terminal view
        var view: NSView? = hitView
        while let v = view {
            if let tv = v as? LocalProcessTerminalView { return tv }
            view = v.superview
        }
        return nil
    }
}

// MARK: - Terminal Paste Fix

/// Intercepts Cmd+V paste events and sends large text in chunks with
/// small delays between them. SwiftTerm's `LocalProcess.send()` writes
/// the entire paste in one `DispatchIO.write()` call — if the PTY buffer
/// fills up (~4KB), excess data is silently dropped.
@MainActor
enum TerminalPasteFix {
    /// Chunk size in bytes. PTY buffers are typically 4KB; use 1KB chunks
    /// to leave headroom for bracketed paste sequences and tmux overhead.
    private static let chunkSize = 1024

    /// Delay between chunks in seconds. Just enough for the PTY to drain.
    private static let chunkDelay: TimeInterval = 0.01

    // Local copies to avoid concurrency warnings on SwiftTerm's mutable statics.
    private static let bracketedPasteStart: [UInt8] = [0x1b, 0x5b, 0x32, 0x30, 0x30, 0x7e]
    private static let bracketedPasteEnd: [UInt8] = [0x1b, 0x5b, 0x32, 0x30, 0x31, 0x7e]

    private static var monitor: Any?

    static func install() {
        guard monitor == nil else { return }

        // Monitor Cmd+V keyDown events
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            guard modifiers == .command,
                  event.charactersIgnoringModifiers == "v",
                  let text = NSPasteboard.general.string(forType: .string),
                  text.utf8.count > chunkSize,
                  let terminalView = findFirstResponderTerminalView(for: event)
            else {
                return event
            }

            // We have a large paste targeting a terminal view — handle it ourselves.
            chunkedPaste(text: text, into: terminalView)

            // Consume the event so SwiftTerm doesn't also paste.
            return nil
        }
    }

    private static func chunkedPaste(text: String, into terminalView: LocalProcessTerminalView) {
        let terminal = terminalView.getTerminal()

        // Send bracketed paste start if the terminal requested it.
        if terminal.bracketedPasteMode {
            terminalView.send(data: bracketedPasteStart[0...])
        }

        let bytes = Array(text.utf8)
        var offset = 0

        func sendNextChunk() {
            let end = min(offset + chunkSize, bytes.count)
            terminalView.send(data: bytes[offset..<end][...])
            offset = end

            if offset < bytes.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + chunkDelay) {
                    MainActor.assumeIsolated {
                        sendNextChunk()
                    }
                }
            } else if terminal.bracketedPasteMode {
                terminalView.send(data: bracketedPasteEnd[0...])
            }
        }

        sendNextChunk()
    }

    private static func findFirstResponderTerminalView(for event: NSEvent) -> LocalProcessTerminalView? {
        guard let window = event.window,
              let responder = window.firstResponder as? NSView
        else { return nil }
        var view: NSView? = responder
        while let v = view {
            if let tv = v as? LocalProcessTerminalView { return tv }
            view = v.superview
        }
        return nil
    }
}

// MARK: - Color Helpers

extension NSColor {
    public convenience init(hex: String) {
        let h = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        let scanner = Scanner(string: h)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let b = CGFloat(rgb & 0xFF) / 255.0
        self.init(srgbRed: r, green: g, blue: b, alpha: 1.0)
    }
}

// SwiftTerm.Color cannot have convenience inits added via extension,
// so use a factory function instead.
private func swiftTermColor(hex: String) -> SwiftTerm.Color {
    let h = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
    let scanner = Scanner(string: h)
    var rgb: UInt64 = 0
    scanner.scanHexInt64(&rgb)

    let r = UInt16((rgb >> 16) & 0xFF)
    let g = UInt16((rgb >> 8) & 0xFF)
    let b = UInt16(rgb & 0xFF)
    // SwiftTerm Color uses 0–65535 range
    return SwiftTerm.Color(red: r * 257, green: g * 257, blue: b * 257)
}
