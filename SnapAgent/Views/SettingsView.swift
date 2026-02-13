import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage(Constants.Keys.afterCaptureAction) private var afterCaptureAction = Constants.Defaults.afterCaptureAction.rawValue
    @AppStorage(Constants.Keys.imageFormat) private var imageFormat = Constants.Defaults.imageFormat.rawValue
    @AppStorage(Constants.Keys.cleanupStrategy) private var cleanupStrategy = Constants.Defaults.cleanupStrategy.rawValue
    @AppStorage(Constants.Keys.cleanupThreshold) private var cleanupThreshold = Constants.Defaults.cleanupThreshold.rawValue
    @AppStorage(Constants.Keys.launchAtLogin) private var launchAtLogin = Constants.Defaults.launchAtLogin
    @AppStorage(Constants.Keys.showNotification) private var showNotification = Constants.Defaults.showNotification
    @AppStorage(Constants.Keys.screenshotDirectory) private var screenshotDirectory = Constants.defaultScreenshotDirectory.path

    @ObservedObject var hotkeyManager: HotkeyManager
    @ObservedObject var cleanupManager: CleanupManager

    @State private var isRecordingRegionHotkey = false
    @State private var isRecordingFullscreenHotkey = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 12)

            TabView {
                generalTab
                    .tabItem { Label("General", systemImage: "gearshape") }

                captureTab
                    .tabItem { Label("Capture", systemImage: "camera") }

                cleanupTab
                    .tabItem { Label("Cleanup", systemImage: "trash") }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .frame(width: 460, height: 380)
    }

    // MARK: - General Tab

    private var generalTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hotkeys
                SettingsSection(title: "Hotkeys", icon: "command") {
                    VStack(spacing: 12) {
                        HotkeyRow(
                            label: "Region capture",
                            shortcut: hotkeyManager.regionHotkeyDescription,
                            isRecording: $isRecordingRegionHotkey,
                            onTap: {
                                isRecordingRegionHotkey.toggle()
                                isRecordingFullscreenHotkey = false
                            }
                        )
                        if isRecordingRegionHotkey {
                            HotkeyRecorderView(
                                onRecorded: { keyCode, modifiers in
                                    hotkeyManager.updateRegionHotkey(keyCode: keyCode, modifiers: modifiers)
                                    isRecordingRegionHotkey = false
                                }
                            )
                            .frame(height: 1)
                        }

                        Divider()

                        HotkeyRow(
                            label: "Full screen capture",
                            shortcut: hotkeyManager.fullscreenHotkeyDescription,
                            isRecording: $isRecordingFullscreenHotkey,
                            onTap: {
                                isRecordingFullscreenHotkey.toggle()
                                isRecordingRegionHotkey = false
                            }
                        )
                        if isRecordingFullscreenHotkey {
                            HotkeyRecorderView(
                                onRecorded: { keyCode, modifiers in
                                    hotkeyManager.updateFullscreenHotkey(keyCode: keyCode, modifiers: modifiers)
                                    isRecordingFullscreenHotkey = false
                                }
                            )
                            .frame(height: 1)
                        }
                    }
                }

                // Startup
                SettingsSection(title: "Startup", icon: "power") {
                    VStack(spacing: 12) {
                        SettingsToggle(
                            title: "Launch at login",
                            description: "Start SnapAgent when you log in",
                            isOn: $launchAtLogin
                        )
                        .onChange(of: launchAtLogin) { enabled in
                            do {
                                if enabled {
                                    try SMAppService.mainApp.register()
                                } else {
                                    try SMAppService.mainApp.unregister()
                                }
                            } catch {
                                print("Failed to update launch at login: \(error)")
                                launchAtLogin = !enabled
                            }
                        }

                        Divider()

                        SettingsToggle(
                            title: "Show notifications",
                            description: "Notify after each capture",
                            isOn: $showNotification
                        )
                    }
                }

                // Storage
                SettingsSection(title: "Storage", icon: "folder") {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Screenshot folder")
                                .font(.system(size: 12, weight: .medium))
                            Text(screenshotDirectory)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.head)
                        }
                        Spacer()
                        Button("Change...") {
                            chooseDirectory()
                        }
                        .controlSize(.small)
                    }
                }
            }
            .padding(16)
        }
    }

    // MARK: - Capture Tab

    private var captureTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                SettingsSection(title: "After Capture", icon: "arrow.right.circle") {
                    Picker("Action", selection: $afterCaptureAction) {
                        ForEach(AfterCaptureAction.allCases) { action in
                            Text(action.rawValue).tag(action.rawValue)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.radioGroup)
                }

                SettingsSection(title: "Image Format", icon: "photo") {
                    Picker("Format", selection: $imageFormat) {
                        ForEach(ImageFormat.allCases) { format in
                            Text(format.rawValue).tag(format.rawValue)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.radioGroup)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Cleanup Tab

    private var cleanupTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                SettingsSection(title: "Strategy", icon: "clock.arrow.circlepath") {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Cleanup mode", selection: $cleanupStrategy) {
                            ForEach(CleanupStrategy.allCases) { strategy in
                                Text(strategy.rawValue).tag(strategy.rawValue)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.radioGroup)

                        if cleanupStrategy != CleanupStrategy.manual.rawValue {
                            Divider()
                            Picker("Delete after:", selection: $cleanupThreshold) {
                                ForEach(CleanupThreshold.allCases) { threshold in
                                    Text(threshold.rawValue).tag(threshold.rawValue)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                }

                SettingsSection(title: "Actions", icon: "exclamationmark.triangle") {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Delete all screenshots")
                                .font(.system(size: 12, weight: .medium))
                            Text("This cannot be undone")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Clean All") {
                            cleanupManager.cleanAll()
                        }
                        .controlSize(.small)
                        .tint(.red)
                    }
                }
            }
            .padding(16)
        }
        .onChange(of: cleanupStrategy) { _ in
            cleanupManager.startTimerIfNeeded()
        }
        .onChange(of: cleanupThreshold) { _ in
            cleanupManager.startTimerIfNeeded()
        }
    }

    // MARK: - Helpers

    private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.directoryURL = URL(fileURLWithPath: screenshotDirectory)

        if panel.runModal() == .OK, let url = panel.url {
            screenshotDirectory = url.path
        }
    }
}

// MARK: - Settings Section

private struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            content
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.03))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                )
        }
    }
}

// MARK: - Hotkey Row

private struct HotkeyRow: View {
    let label: String
    let shortcut: String
    @Binding var isRecording: Bool
    let onTap: () -> Void

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium))
            Spacer()
            Button(action: onTap) {
                Text(isRecording ? "Press keys..." : shortcut)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(isRecording ? Color.accentColor.opacity(0.1) : Color.primary.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(isRecording ? Color.accentColor.opacity(0.4) : Color.primary.opacity(0.1), lineWidth: 0.5)
                    )
            }
            .buttonStyle(.borderless)
        }
    }
}

// MARK: - Settings Toggle

private struct SettingsToggle: View {
    let title: String
    let description: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .controlSize(.small)
                .labelsHidden()
        }
    }
}

// MARK: - Hotkey Recorder

struct HotkeyRecorderView: NSViewRepresentable {
    var onRecorded: (UInt32, NSEvent.ModifierFlags) -> Void

    func makeNSView(context: Context) -> HotkeyRecorderNSView {
        let view = HotkeyRecorderNSView()
        view.onRecorded = onRecorded
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: HotkeyRecorderNSView, context: Context) {}
}

class HotkeyRecorderNSView: NSView {
    var onRecorded: ((UInt32, NSEvent.ModifierFlags) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        let modifiers = event.modifierFlags.intersection([.command, .shift, .option, .control])
        guard !modifiers.isEmpty else { return }
        onRecorded?(UInt32(event.keyCode), modifiers)
    }
}
