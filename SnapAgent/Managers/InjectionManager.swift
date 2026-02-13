import Foundation
import AppKit
import Carbon

class InjectionManager {
    /// The last known terminal app the user was working in
    private(set) var lastTerminalApp: NSRunningApplication?

    /// Fallback: the app that was frontmost when capture was triggered
    private(set) var appAtCaptureTime: NSRunningApplication?

    private var observer: NSObjectProtocol?

    /// Well-known terminal bundle identifiers
    private static let terminalBundleIDs: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "dev.warp.Warp-Stable",
        "com.mitchellh.ghostty",
        "co.zeit.hyper",
        "com.github.wez.wezterm",
        "net.kovidgoyal.kitty",
        "io.alacritty",
        "com.microsoft.VSCode",
        "com.todesktop.230313mzl4w4u92",  // Cursor
    ]

    init() {
        startTrackingTerminal()
    }

    /// Watch for app activations and remember the most recent terminal
    private func startTrackingTerminal() {
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let bundleID = app.bundleIdentifier else { return }

            if Self.terminalBundleIDs.contains(bundleID) {
                self?.lastTerminalApp = app
            }
        }

        // Seed with current frontmost app if it's a terminal
        if let frontmost = NSWorkspace.shared.frontmostApplication,
           let bundleID = frontmost.bundleIdentifier,
           Self.terminalBundleIDs.contains(bundleID) {
            lastTerminalApp = frontmost
        }
    }

    /// Save the frontmost app before capture starts (fallback for paste target)
    func saveAppAtCaptureTime() {
        appAtCaptureTime = NSWorkspace.shared.frontmostApplication
    }

    /// Inject a file path into the last known terminal
    /// Uses clipboard + simulated Cmd+V paste
    func injectPath(_ path: String, action: AfterCaptureAction) {
        guard action != .nothing else { return }

        // Set the clipboard to the file path
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(path, forType: .string)

        guard action == .copyAndPaste else { return }

        // Pick the paste target: prefer last known terminal, fall back to
        // whatever app was active when the hotkey was pressed
        let target = resolveTarget()

        guard let target, !target.isTerminated else {
            print("[SnapAgent] No paste target found. Path copied to clipboard.")
            return
        }

        print("[SnapAgent] Pasting to: \(target.localizedName ?? "unknown") (\(target.bundleIdentifier ?? "?"))")

        target.activate()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.simulatePaste()
        }
    }

    private func resolveTarget() -> NSRunningApplication? {
        // Prefer the tracked terminal
        if let terminal = lastTerminalApp, !terminal.isTerminated {
            return terminal
        }

        // Fall back to app that was frontmost when hotkey was pressed
        if let fallback = appAtCaptureTime, !fallback.isTerminated {
            print("[SnapAgent] No tracked terminal found, falling back to frontmost app at capture time")
            return fallback
        }

        return nil
    }

    /// Simulate Cmd+V keystroke using CGEvent
    private func simulatePaste() {
        guard PermissionsHelper.isAccessibilityGranted else {
            print("[SnapAgent] Accessibility permission not granted, cannot simulate paste")
            return
        }

        let source = CGEventSource(stateID: .hidSystemState)

        // Key code for 'V' is 9
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)

        // Set Cmd modifier
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    deinit {
        if let observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }
}
