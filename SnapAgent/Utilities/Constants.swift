import Foundation

enum Constants {
    static let defaultScreenshotDirectory: URL = {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".ai-screenshots")
    }()

    static let appName = "SnapAgent"

    // UserDefaults keys
    enum Keys {
        static let screenshotDirectory = "screenshotDirectory"
        static let afterCaptureAction = "afterCaptureAction"
        static let imageFormat = "imageFormat"
        static let cleanupStrategy = "cleanupStrategy"
        static let cleanupThreshold = "cleanupThreshold"
        static let launchAtLogin = "launchAtLogin"
        static let showNotification = "showNotification"
        static let hotkeyKeyCode = "hotkeyKeyCode"
        static let hotkeyModifiers = "hotkeyModifiers"
        static let fullscreenHotkeyKeyCode = "fullscreenHotkeyKeyCode"
        static let fullscreenHotkeyModifiers = "fullscreenHotkeyModifiers"
        static let onboardingComplete = "onboardingComplete"
    }

    // Defaults
    enum Defaults {
        static let afterCaptureAction = AfterCaptureAction.copyAndPaste
        static let imageFormat = ImageFormat.png
        static let cleanupStrategy = CleanupStrategy.timeBased
        static let cleanupThreshold = CleanupThreshold.twentyFourHours
        static let launchAtLogin = false
        static let showNotification = true
    }
}

enum AfterCaptureAction: String, CaseIterable, Identifiable {
    case copyAndPaste = "Copy + Paste"
    case copyOnly = "Copy Only"
    case nothing = "Nothing"

    var id: String { rawValue }
}

enum ImageFormat: String, CaseIterable, Identifiable {
    case png = "PNG"
    case jpeg = "JPEG"

    var id: String { rawValue }

    var fileExtension: String {
        switch self {
        case .png: return "png"
        case .jpeg: return "jpg"
        }
    }

    var screencaptureType: String {
        switch self {
        case .png: return "png"
        case .jpeg: return "jpg"
        }
    }
}

enum CleanupStrategy: String, CaseIterable, Identifiable {
    case timeBased = "Time-based"
    case manual = "Manual"
    case both = "Both"

    var id: String { rawValue }
}

enum CleanupThreshold: String, CaseIterable, Identifiable {
    case oneHour = "1 Hour"
    case sixHours = "6 Hours"
    case twentyFourHours = "24 Hours"
    case sevenDays = "7 Days"

    var id: String { rawValue }

    var timeInterval: TimeInterval {
        switch self {
        case .oneHour: return 3600
        case .sixHours: return 3600 * 6
        case .twentyFourHours: return 3600 * 24
        case .sevenDays: return 3600 * 24 * 7
        }
    }
}
