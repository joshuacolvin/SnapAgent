import Foundation
import AppKit
import ApplicationServices

enum PermissionsHelper {
    // MARK: - Accessibility

    /// Check if the app has Accessibility permission
    static var isAccessibilityGranted: Bool {
        AXIsProcessTrusted()
    }

    /// Request Accessibility permission by opening System Settings directly
    @discardableResult
    static func requestAccessibility() -> Bool {
        let trusted = AXIsProcessTrusted()
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

    /// Request Screen Recording permission via the system dialog
    /// The system dialog includes its own "Open System Settings" button as a fallback.
    @discardableResult
    static func requestScreenRecording() -> Bool {
        CGRequestScreenCaptureAccess()
    }

    /// Open System Settings to the Screen Recording pane
    static func openScreenRecordingSettings() {
        let urls = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture",
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ScreenCapture"
        ]
        for urlString in urls {
            if let url = URL(string: urlString), NSWorkspace.shared.open(url) {
                return
            }
        }
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
    }
}
