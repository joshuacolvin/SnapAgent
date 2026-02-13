import SwiftUI
import AppKit

struct ScreenshotRow: View {
    let screenshot: Screenshot
    let onCopyPath: () -> Void
    let onReveal: () -> Void
    let onDelete: () -> Void

    @State private var thumbnail: NSImage?

    var body: some View {
        HStack(spacing: 10) {
            // Thumbnail
            Group {
                if let thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 36)
                        .clipped()
                        .cornerRadius(4)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 48, height: 36)
                        .cornerRadius(4)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(screenshot.fileName)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)

                HStack(spacing: 6) {
                    Text(screenshot.age)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                    Text(screenshot.fileSizeFormatted)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Actions
            HStack(spacing: 4) {
                Button(action: onCopyPath) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 11))
                }
                .buttonStyle(.borderless)
                .help("Copy path")

                Button(action: onReveal) {
                    Image(systemName: "folder")
                        .font(.system(size: 11))
                }
                .buttonStyle(.borderless)
                .help("Reveal in Finder")

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
                .help("Delete")
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .task {
            thumbnail = await loadThumbnail()
        }
    }

    private func loadThumbnail() async -> NSImage? {
        guard screenshot.exists else { return nil }
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let image = NSImage(contentsOfFile: screenshot.filePath) else {
                    continuation.resume(returning: nil)
                    return
                }
                // Create a scaled-down thumbnail
                let targetSize = NSSize(width: 96, height: 72)
                let thumb = NSImage(size: targetSize)
                thumb.lockFocus()
                image.draw(
                    in: NSRect(origin: .zero, size: targetSize),
                    from: NSRect(origin: .zero, size: image.size),
                    operation: .copy,
                    fraction: 1.0
                )
                thumb.unlockFocus()
                continuation.resume(returning: thumb)
            }
        }
    }
}
