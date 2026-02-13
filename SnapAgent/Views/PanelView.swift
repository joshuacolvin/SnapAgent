import SwiftUI

struct PanelView: View {
    @ObservedObject var store: ScreenshotStore
    @ObservedObject var hotkeyManager: HotkeyManager
    @ObservedObject var cleanupManager: CleanupManager

    let onCaptureRegion: () -> Void
    let onCaptureFullscreen: () -> Void

    @State private var showSettings = false
    @State private var hasAccessibility = PermissionsHelper.isAccessibilityGranted
    @State private var permissionTimer: Timer?

    private let columns = [
        GridItem(.adaptive(minimum: 170, maximum: 220), spacing: 14)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 14)

            // Permission banner
            if !hasAccessibility {
                permissionBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Content
            if store.screenshots.isEmpty {
                emptyState
            } else {
                screenshotGrid
            }

            // Footer
            footer
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.bar)
        }
        .background(.background)
        .frame(minWidth: 500, idealWidth: 540, minHeight: 420, idealHeight: 520)
        .onAppear {
            hasAccessibility = PermissionsHelper.isAccessibilityGranted
            if !hasAccessibility {
                permissionTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
                    let granted = PermissionsHelper.isAccessibilityGranted
                    if granted {
                        withAnimation { hasAccessibility = true }
                        permissionTimer?.invalidate()
                        permissionTimer = nil
                    }
                }
            }
        }
        .onDisappear {
            permissionTimer?.invalidate()
            permissionTimer = nil
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(hotkeyManager: hotkeyManager, cleanupManager: cleanupManager)
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "camera.aperture")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.tint)

                Text("SnapAgent")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }

            Spacer()
        }
    }

    // MARK: - Permission Banner

    private var permissionBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundStyle(.orange)

            Text("Accessibility permission required for auto-paste")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            Spacer()

            Button(action: { PermissionsHelper.requestAccessibility() }) {
                Text("Grant Access")
                    .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.orange.opacity(0.08))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.tint.opacity(0.08))
                    .frame(width: 80, height: 80)

                Image(systemName: "camera.on.rectangle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.tint.opacity(0.5))
            }

            VStack(spacing: 6) {
                Text("No screenshots yet")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)

                Text("Use **\(hotkeyManager.regionHotkeyDescription)** for region\nor **\(hotkeyManager.fullscreenHotkeyDescription)** for full screen")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Screenshot Grid

    private var screenshotGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(store.screenshots) { screenshot in
                    ScreenshotCard(
                        screenshot: screenshot,
                        onCopyPath: { copyPath(screenshot) },
                        onReveal: { revealInFinder(screenshot) },
                        onDelete: { withAnimation(.easeOut(duration: 0.2)) { store.remove(screenshot) } },
                        onOpen: { openInPreview(screenshot) }
                    )
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
            }
            .padding(20)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Text("\(store.screenshots.count)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(.tint.opacity(store.screenshots.isEmpty ? 0.3 : 1.0))
                    )

                Text(store.screenshots.count == 1 ? "screenshot" : "screenshots")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            if !store.screenshots.isEmpty {
                Button(action: { cleanupManager.cleanAll() }) {
                    HStack(spacing: 5) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Clear All")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.red.opacity(0.8))
                    )
                }
                .buttonStyle(.borderless)
            }

            Spacer()

            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .help("Settings")

            Button("Quit") { NSApplication.shared.terminate(nil) }
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .buttonStyle(.borderless)
        }
    }

    // MARK: - Actions

    private func copyPath(_ screenshot: Screenshot) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(screenshot.filePath, forType: .string)
    }

    private func revealInFinder(_ screenshot: Screenshot) {
        NSWorkspace.shared.selectFile(screenshot.filePath, inFileViewerRootedAtPath: "")
    }

    private func openInPreview(_ screenshot: Screenshot) {
        NSWorkspace.shared.open(URL(fileURLWithPath: screenshot.filePath))
    }
}

// MARK: - Capture Button

private struct CaptureButton: View {
    let title: String
    let icon: String
    let shortcut: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.primary.opacity(0.08) : Color.primary.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
        }
        .buttonStyle(.borderless)
        .onHover { isHovered = $0 }
        .help("\(title) (\(shortcut))")
    }
}
