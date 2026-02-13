import Foundation
import SwiftUI

@MainActor
class ScreenshotStore: ObservableObject {
    @Published var screenshots: [Screenshot] = []

    private let storageKey = "savedScreenshots"

    init() {
        load()
    }

    func add(_ screenshot: Screenshot) {
        screenshots.insert(screenshot, at: 0)
        save()
    }

    func remove(_ screenshot: Screenshot) {
        // Delete file from disk
        try? FileManager.default.removeItem(atPath: screenshot.filePath)
        screenshots.removeAll { $0.id == screenshot.id }
        save()
    }

    func removeAll() {
        for screenshot in screenshots {
            try? FileManager.default.removeItem(atPath: screenshot.filePath)
        }
        screenshots.removeAll()
        save()
    }

    func removeExpired(olderThan threshold: TimeInterval) {
        let cutoff = Date().addingTimeInterval(-threshold)
        let expired = screenshots.filter { $0.createdAt < cutoff }
        for screenshot in expired {
            try? FileManager.default.removeItem(atPath: screenshot.filePath)
        }
        screenshots.removeAll { $0.createdAt < cutoff }
        save()
    }

    /// Remove screenshots whose files no longer exist on disk
    func pruneOrphaned() {
        screenshots.removeAll { !$0.exists }
        save()
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(screenshots) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Screenshot].self, from: data) else {
            return
        }
        screenshots = decoded
        pruneOrphaned()
    }
}
