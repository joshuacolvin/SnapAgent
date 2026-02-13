import Foundation
import Combine

@MainActor
class CleanupManager: ObservableObject {
    private var timer: Timer?
    private weak var store: ScreenshotStore?

    private var cleanupStrategy: CleanupStrategy {
        if let raw = UserDefaults.standard.string(forKey: Constants.Keys.cleanupStrategy),
           let strategy = CleanupStrategy(rawValue: raw) {
            return strategy
        }
        return Constants.Defaults.cleanupStrategy
    }

    private var cleanupThreshold: CleanupThreshold {
        if let raw = UserDefaults.standard.string(forKey: Constants.Keys.cleanupThreshold),
           let threshold = CleanupThreshold(rawValue: raw) {
            return threshold
        }
        return Constants.Defaults.cleanupThreshold
    }

    func configure(store: ScreenshotStore) {
        self.store = store
        startTimerIfNeeded()
    }

    func startTimerIfNeeded() {
        timer?.invalidate()
        timer = nil

        guard cleanupStrategy == .timeBased || cleanupStrategy == .both else {
            return
        }

        // Run cleanup every 5 minutes
        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.runTimedCleanup()
            }
        }

        // Also run immediately
        runTimedCleanup()
    }

    func runTimedCleanup() {
        store?.removeExpired(olderThan: cleanupThreshold.timeInterval)
    }

    func cleanAll() {
        store?.removeAll()
    }

    deinit {
        timer?.invalidate()
    }
}
