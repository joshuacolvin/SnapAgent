import Foundation
import AppKit

enum CaptureMode {
    case region      // interactive region selection (-i)
    case fullscreen  // capture entire main display (-m)
}

class ScreenshotManager {
    private var screenshotDirectory: URL {
        if let saved = UserDefaults.standard.string(forKey: Constants.Keys.screenshotDirectory) {
            return URL(fileURLWithPath: saved)
        }
        return Constants.defaultScreenshotDirectory
    }

    private var imageFormat: ImageFormat {
        if let raw = UserDefaults.standard.string(forKey: Constants.Keys.imageFormat),
           let format = ImageFormat(rawValue: raw) {
            return format
        }
        return Constants.Defaults.imageFormat
    }

    /// Ensure the screenshot directory exists
    func ensureDirectoryExists() throws {
        try FileManager.default.createDirectory(
            at: screenshotDirectory,
            withIntermediateDirectories: true
        )
    }

    /// Generate a unique file path for a new screenshot
    func generateFilePath() -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let timestamp = formatter.string(from: Date())
        let fileName = "screenshot-\(timestamp).\(imageFormat.fileExtension)"
        return screenshotDirectory.appendingPathComponent(fileName)
    }

    /// Capture a screenshot using macOS screencapture CLI
    /// Returns the file path if successful, nil if user cancelled
    func capture(mode: CaptureMode = .region) async -> Screenshot? {
        do {
            try ensureDirectoryExists()
        } catch {
            print("Failed to create screenshot directory: \(error)")
            return nil
        }

        let outputPath = generateFilePath()
        let format = imageFormat

        // Run the blocking process on a dedicated thread to avoid
        // starving the cooperative thread pool
        let success = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")

                var args: [String] = []
                switch mode {
                case .region:
                    args.append("-i")     // interactive region selection
                case .fullscreen:
                    args.append("-m")     // main display only
                }
                args += ["-t", format.screencaptureType, outputPath.path]
                process.arguments = args

                do {
                    try process.run()
                    process.waitUntilExit()
                    continuation.resume(returning: process.terminationStatus == 0)
                } catch {
                    print("screencapture failed: \(error)")
                    continuation.resume(returning: false)
                }
            }
        }

        guard success else { return nil }

        // Check if the user cancelled (file won't exist if Escape was pressed)
        guard FileManager.default.fileExists(atPath: outputPath.path) else {
            return nil
        }

        return Screenshot(filePath: outputPath.path, format: format.rawValue)
    }
}
