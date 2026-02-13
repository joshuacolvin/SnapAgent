import Foundation
import AppKit

struct Screenshot: Identifiable, Codable, Equatable {
    let id: UUID
    let filePath: String
    let createdAt: Date
    let format: String

    var url: URL {
        URL(fileURLWithPath: filePath)
    }

    var fileName: String {
        url.lastPathComponent
    }

    var exists: Bool {
        FileManager.default.fileExists(atPath: filePath)
    }

    var fileSize: Int64? {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: filePath),
              let size = attrs[.size] as? Int64 else {
            return nil
        }
        return size
    }

    var fileSizeFormatted: String {
        guard let size = fileSize else { return "Unknown" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    var age: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    init(filePath: String, format: String) {
        self.id = UUID()
        self.filePath = filePath
        self.createdAt = Date()
        self.format = format
    }
}
