import SwiftUI

struct MenuBarView: View {
    @ObservedObject var store: ScreenshotStore
    @ObservedObject var hotkeyManager: HotkeyManager
    @ObservedObject var cleanupManager: CleanupManager

    let onCaptureRegion: () -> Void
    let onCaptureFullscreen: () -> Void

    @State private var showSettings = false
    @State private var hasAccessibility = PermissionsHelper.isAccessibilityGranted

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("SnapAgent")
                    .font(.headline)
                Spacer()
                Text("\(store.screenshots.count) screenshots")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            // Permission banner
            if !hasAccessibility {
                Divider()
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 12))
                    Text("Accessibility permission needed for auto-paste")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Grant") {
                        PermissionsHelper.requestAccessibility()
                    }
                    .font(.system(size: 11))
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.08))
            }

            Divider()

            // Capture buttons
            Button(action: onCaptureRegion) {
                HStack {
                    Image(systemName: "rectangle.dashed")
                    Text("Capture Region")
                    Spacer()
                    Text(hotkeyManager.regionHotkeyDescription)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            }
            .buttonStyle(.borderless)

            Button(action: onCaptureFullscreen) {
                HStack {
                    Image(systemName: "rectangle.inset.filled")
                    Text("Capture Full Screen")
                    Spacer()
                    Text(hotkeyManager.fullscreenHotkeyDescription)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            }
            .buttonStyle(.borderless)

            Divider()

            // Screenshot list
            if store.screenshots.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "camera.on.rectangle")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                    Text("No screenshots yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Press \(hotkeyManager.regionHotkeyDescription) to capture")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(store.screenshots) { screenshot in
                            ScreenshotRow(
                                screenshot: screenshot,
                                onCopyPath: { copyPath(screenshot) },
                                onReveal: { revealInFinder(screenshot) },
                                onDelete: { store.remove(screenshot) }
                            )
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: 300)
            }

            Divider()

            // Footer actions
            HStack {
                if !store.screenshots.isEmpty {
                    Button("Clean All") {
                        cleanupManager.cleanAll()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }

                Spacer()

                Button(action: { showSettings = true }) {
                    Image(systemName: "gear")
                        .font(.system(size: 12))
                }
                .buttonStyle(.borderless)

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 320)
        .onAppear {
            hasAccessibility = PermissionsHelper.isAccessibilityGranted
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(hotkeyManager: hotkeyManager, cleanupManager: cleanupManager)
        }
    }

    private func copyPath(_ screenshot: Screenshot) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(screenshot.filePath, forType: .string)
    }

    private func revealInFinder(_ screenshot: Screenshot) {
        NSWorkspace.shared.selectFile(screenshot.filePath, inFileViewerRootedAtPath: "")
    }
}
