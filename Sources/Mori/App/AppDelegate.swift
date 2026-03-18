import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        // TODO: Phase 3 — Initialize main window, enforce single instance
    }

    func applicationWillTerminate(_ notification: Notification) {
        // TODO: Phase 5 — Persist UI state before exit
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }
}
