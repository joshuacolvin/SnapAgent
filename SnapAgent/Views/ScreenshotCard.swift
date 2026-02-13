import SwiftUI
import AppKit

struct ScreenshotCard: View {
    let screenshot: Screenshot
    let onCopyPath: () -> Void
    let onReveal: () -> Void
    let onDelete: () -> Void
    let onOpen: () -> Void

    @State private var thumbnail: NSImage?
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail
            ZStack(alignment: .bottom) {
                Group {
                    if let thumbnail {
                        Image(nsImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 130)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color.primary.opacity(0.03))
                            .frame(height: 130)
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.quaternary)
                            }
                    }
                }
                .onTapGesture(perform: onOpen)

                // Gradient overlay for action buttons
                if isHovered {
                    LinearGradient(
                        colors: [.black.opacity(0.7), .black.opacity(0.3), .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: 70)
                    .allowsHitTesting(false)

                    // Action buttons
                    HStack(spacing: 8) {
                        CardAction(icon: "doc.on.clipboard", action: onCopyPath, help: "Copy path")
                        CardAction(icon: "folder", action: onReveal, help: "Reveal in Finder")

                        Spacer()

                        CardAction(icon: "trash", isDestructive: true, action: onDelete, help: "Delete")
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(screenshot.fileName)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)

                HStack(spacing: 4) {
                    Text(screenshot.age)
                    Text("\u{00B7}")
                    Text(screenshot.fileSizeFormatted)
                }
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 6)
            .padding(.top, 8)
            .padding(.bottom, 6)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? Color.primary.opacity(0.04) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(isHovered ? Color.primary.opacity(0.1) : Color.clear, lineWidth: 0.5)
        )
        .shadow(
            color: isHovered ? .black.opacity(0.08) : .clear,
            radius: isHovered ? 8 : 0,
            y: isHovered ? 2 : 0
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .onHover { isHovered = $0 }
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
                let targetSize = NSSize(width: 400, height: 260)
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

// MARK: - Card Action Button

private struct CardAction: View {
    let icon: String
    var isDestructive: Bool = false
    let action: () -> Void
    let help: String

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isDestructive ? .red : .white)
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(isDestructive
                            ? Color.red.opacity(isHovered ? 0.4 : 0.2)
                            : Color.white.opacity(isHovered ? 0.4 : 0.2))
                )
                .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
        }
        .buttonStyle(.borderless)
        .scaleEffect(isHovered ? 1.1 : 1.0)
        .animation(.easeOut(duration: 0.1), value: isHovered)
        .onHover { isHovered = $0 }
        .help(help)
    }
}
