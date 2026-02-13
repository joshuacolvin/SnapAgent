import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var hasAccessibility = PermissionsHelper.isAccessibilityGranted
    @State private var hasScreenRecording = PermissionsHelper.isScreenRecordingGranted

    private var allGranted: Bool {
        hasAccessibility && hasScreenRecording
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)

            Text("Welcome to SnapAgent")
                .font(.title2)
                .fontWeight(.semibold)

            Text("SnapAgent needs two permissions to capture screenshots and paste paths into your terminal.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .frame(maxWidth: 320)

            VStack(spacing: 12) {
                permissionRow(
                    title: "Accessibility",
                    detail: "Paste screenshot paths into your terminal",
                    granted: hasAccessibility,
                    action: {
                        PermissionsHelper.requestAccessibility()
                        startPolling()
                    }
                )

                permissionRow(
                    title: "Screen Recording",
                    detail: "Capture screenshots of your screen",
                    granted: hasScreenRecording,
                    action: {
                        PermissionsHelper.requestScreenRecording()
                        startPolling()
                    }
                )
            }

            if allGranted {
                Button("Get Started") {
                    markOnboardingComplete()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Continue Without Permissions") {
                    markOnboardingComplete()
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(32)
        .frame(width: 440, height: 380)
    }

    @ViewBuilder
    private func permissionRow(title: String, detail: String, granted: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Image(systemName: granted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(granted ? .green : .red)
                .font(.system(size: 18))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout)
                    .fontWeight(.medium)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if !granted {
                Button("Grant") {
                    action()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))
    }

    private func startPolling() {
        Task {
            for _ in 0..<30 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                let accessibility = PermissionsHelper.isAccessibilityGranted
                let screenRecording = PermissionsHelper.isScreenRecordingGranted
                await MainActor.run {
                    hasAccessibility = accessibility
                    hasScreenRecording = screenRecording
                }
                if accessibility && screenRecording { break }
            }
        }
    }

    private func markOnboardingComplete() {
        UserDefaults.standard.set(true, forKey: Constants.Keys.onboardingComplete)
    }
}
