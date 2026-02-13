import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var hasPermission = PermissionsHelper.isAccessibilityGranted

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)

            Text("Welcome to SnapAgent")
                .font(.title2)
                .fontWeight(.semibold)

            Text("SnapAgent needs Accessibility permission to paste screenshot paths into your terminal automatically.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .frame(maxWidth: 300)

            // Permission status
            HStack(spacing: 8) {
                Image(systemName: hasPermission ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(hasPermission ? .green : .red)
                Text(hasPermission ? "Accessibility permission granted" : "Accessibility permission required")
                    .font(.callout)
            }
            .padding(.vertical, 4)

            if !hasPermission {
                Button("Grant Accessibility Permission") {
                    PermissionsHelper.requestAccessibility()
                    // Poll for permission change
                    startPermissionPolling()
                }
                .buttonStyle(.borderedProminent)
            }

            if hasPermission {
                Button("Get Started") {
                    markOnboardingComplete()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Continue Without Paste") {
                    markOnboardingComplete()
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(32)
        .frame(width: 400, height: 340)
    }

    private func startPermissionPolling() {
        // Check every second for 30 seconds after the user opens System Settings
        Task {
            for _ in 0..<30 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                let granted = PermissionsHelper.isAccessibilityGranted
                await MainActor.run {
                    hasPermission = granted
                }
                if granted { break }
            }
        }
    }

    private func markOnboardingComplete() {
        UserDefaults.standard.set(true, forKey: Constants.Keys.onboardingComplete)
    }
}
