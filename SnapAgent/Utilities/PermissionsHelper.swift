import Foundation
import AppKit
import ApplicationServices

enum PermissionsHelper {
    // MARK: - Accessibility

    /// Check if the app has Accessibility permission
    static var isAccessibilityGranted: Bool {
        AXIsProcessTrusted()
    }

    /// Prompt the user for Accessibility permission
    /// Tries the system dialog first, falls back to opening System Settings
    @discardableResult
    static func requestAccessibility() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        if !trusted {
            openAccessibilitySettings()
        }
        return trusted
    }

    /// Open System Settings to the Accessibility pane
    static func openAccessibilitySettings() {
        let urls = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility"
        ]
        for urlString in urls {
            if let url = URL(string: urlString), NSWorkspace.shared.open(url) {
                return
            }
        }
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
    }

    // MARK: - Screen Recording

    /// Check if the app has Screen Recording permission
    static var isScreenRecordingGranted: Bool {
        CGPreflightScreenCaptureAccess()
    }

    /// Request Screen Recording permission (opens System Settings)
    @discardableResult
    static func requestScreenRecording() -> Bool {
        CGRequestScreenCaptureAccess()
    }
}
