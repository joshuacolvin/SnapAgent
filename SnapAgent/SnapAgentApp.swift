import SwiftUI
import UserNotifications

@main
struct SnapAgentApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    let store = ScreenshotStore()
    let hotkeyManager = HotkeyManager()
    let cleanupManager = CleanupManager()
    let screenshotManager = ScreenshotManager()
    let injectionManager = InjectionManager()

    @AppStorage(Constants.Keys.afterCaptureAction) var afterCaptureAction = Constants.Defaults.afterCaptureAction.rawValue
    @AppStorage(Constants.Keys.showNotification) var showNotification = Constants.Defaults.showNotification

    private var panel: NSPanel?
    private var onboardingWindow: NSWindow?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set up cleanup
        cleanupManager.configure(store: store)

        // Set up hotkey handlers
        hotkeyManager.onRegionHotkeyPressed = { [weak self] in
            self?.captureScreenshot(mode: .region)
        }
        hotkeyManager.onFullscreenHotkeyPressed = { [weak self] in
            self?.captureScreenshot(mode: .fullscreen)
        }

        // Set up menu bar status item
        setupStatusItem()

        // Request notification permission (requires app bundle with identifier)
        if Bundle.main.bundleIdentifier != nil {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }

        // Show onboarding if first launch
        if !UserDefaults.standard.bool(forKey: Constants.Keys.onboardingComplete) {
            showOnboarding()
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "camera.aperture", accessibilityDescription: "SnapAgent")
            button.action = #selector(statusItemClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            // Right-click: show context menu
            guard let button = statusItem?.button else { return }

            let menu = NSMenu()
            menu.addItem(withTitle: "Capture Region  \(hotkeyManager.regionHotkeyDescription)",
                         action: #selector(captureRegionAction), keyEquivalent: "")
            menu.addItem(withTitle: "Capture Full Screen  \(hotkeyManager.fullscreenHotkeyDescription)",
                         action: #selector(captureFullscreenAction), keyEquivalent: "")
            menu.addItem(.separator())
            menu.addItem(withTitle: "Quit SnapAgent", action: #selector(quitAction), keyEquivalent: "q")

            for item in menu.items {
                item.target = self
            }

            let point = NSPoint(x: 0, y: button.bounds.maxY + 5)
            menu.popUp(positioning: nil, at: point, in: button)
        } else {
            // Left-click: open panel
            showPanel()
        }
    }

    @objc private func captureRegionAction() { captureScreenshot(mode: .region) }
    @objc private func captureFullscreenAction() { captureScreenshot(mode: .fullscreen) }
    @objc private func quitAction() { NSApplication.shared.terminate(nil) }

    func showPanel() {
        if let panel {
            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let panelView = PanelView(
            store: store,
            hotkeyManager: hotkeyManager,
            cleanupManager: cleanupManager,
            onCaptureRegion: { [weak self] in self?.captureScreenshot(mode: .region) },
            onCaptureFullscreen: { [weak self] in self?.captureScreenshot(mode: .fullscreen) }
        )

        let hostingController = NSHostingController(rootView: panelView)

        let newPanel = NSPanel(contentViewController: hostingController)
        newPanel.title = "SnapAgent"
        newPanel.styleMask = [.titled, .closable, .resizable, .nonactivatingPanel, .fullSizeContentView]
        newPanel.titlebarAppearsTransparent = true
        newPanel.titleVisibility = .hidden
        newPanel.isFloatingPanel = true
        newPanel.level = .floating
        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.setContentSize(NSSize(width: 540, height: 520))
        newPanel.minSize = NSSize(width: 420, height: 360)
        newPanel.center()
        newPanel.isReleasedWhenClosed = false
        newPanel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        panel = newPanel
    }

    private func showOnboarding() {
        let onboardingView = OnboardingView { [weak self] in
            self?.onboardingWindow?.close()
            self?.onboardingWindow = nil
            self?.showPanel()
        }
        let hostingController = NSHostingController(rootView: onboardingView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Welcome to SnapAgent"
        window.styleMask = [.titled, .closable]
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        onboardingWindow = window
    }

    func captureScreenshot(mode: CaptureMode = .region) {
        // Check accessibility permission first
        if !PermissionsHelper.isAccessibilityGranted {
            PermissionsHelper.requestAccessibility()
            return
        }

        // Check screen recording permission
        if !PermissionsHelper.isScreenRecordingGranted {
            PermissionsHelper.requestScreenRecording()
            return
        }

        // Save frontmost app as fallback paste target
        injectionManager.saveAppAtCaptureTime()

        Task {
            guard let screenshot = await screenshotManager.capture(mode: mode) else {
                return // User cancelled
            }

            await MainActor.run {
                store.add(screenshot)

                // Determine action
                let action = AfterCaptureAction(rawValue: afterCaptureAction) ?? .copyAndPaste
                injectionManager.injectPath(screenshot.filePath, action: action)

                // Show notification if enabled
                if showNotification {
                    sendNotification(for: screenshot)
                }
            }
        }
    }

    private func sendNotification(for screenshot: Screenshot) {
        guard Bundle.main.bundleIdentifier != nil else { return }

        let content = UNMutableNotificationContent()
        content.title = "Screenshot Captured"
        content.body = screenshot.fileName
        content.sound = nil

        let request = UNNotificationRequest(
            identifier: screenshot.id.uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
