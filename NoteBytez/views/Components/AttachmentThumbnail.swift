// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  AttachmentThumbnail.swift
//  NoteBytez
//

import SwiftUI

/// Image/PDF icon + filename, per docs/styleGuide.md / S20 — tap opens `AttachmentPreview`.
/// Shows a "downloading…" placeholder while a not-yet-local iCloud file is fetched (no progress
/// bar, matching the scope `AttachmentStorage.ensureDownloaded` documents).
struct AttachmentThumbnail: View {

    let attachment: Attachment
    let action: () -> Void

    private var isImage: Bool {
        (attachment.mimeType ?? "").hasPrefix("image/")
    }

    private var localURL: URL? {
        AttachmentDAL.resolveLocalURL(attachment)
    }

    private var isDownloaded: Bool {
        guard let localURL else { return false }
        return AttachmentStorage.isDownloaded(at: localURL)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: isImage ? "photo" : "doc.richtext")
                    .foregroundStyle(Color.accentColor)
                Text(attachment.fileName ?? "Attachment")
                    .font(.callout)
                    .lineLimit(1)
                if let localURL, !isDownloaded {
                    Text("downloading…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .onAppear { AttachmentStorage.ensureDownloaded(url: localURL) }
                }
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .background(Color.noteBytezSecondarySurface)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(attachment.fileName ?? "Attachment")
    }

}
