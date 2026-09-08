// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  AttachmentPreview.swift
//  NoteBytez
//

import SwiftUI
import PDFKit

/// Full-screen preview overlay for a tapped `AttachmentThumbnail` — per docs/styleGuide.md /
/// S20, same sheet-based full-screen pattern S6's Quick Switcher already establishes on iPhone.
struct AttachmentPreview: View {

    let attachment: Attachment
    @Environment(\.dismiss) private var dismiss

    private var isImage: Bool {
        (attachment.mimeType ?? "").hasPrefix("image/")
    }

    private var localURL: URL? {
        AttachmentDAL.resolveLocalURL(attachment)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let localURL, AttachmentStorage.isDownloaded(at: localURL) {
                    if isImage {
                        AttachmentImageView(url: localURL)
                    } else {
                        AttachmentPDFView(url: localURL)
                    }
                } else {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Downloading…")
                            .foregroundStyle(.secondary)
                    }
                    .onAppear { if let localURL { AttachmentStorage.ensureDownloaded(url: localURL) } }
                }
            }
            .navigationTitle(attachment.fileName ?? "Attachment")
            .noteBytezInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

}

/// Cross-platform image display from a local file `URL` — `Image(uiImage:)`/`Image(nsImage:)`
/// bridge differently per platform, defined once here rather than at the call site (mirrors
/// `PlatformCompatibility.swift`'s existing convention).
private struct AttachmentImageView: View {

    let url: URL

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            platformImage
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }

    private var platformImage: Image {
        guard let data = try? Data(contentsOf: url) else {
            return Image(systemName: "photo")
        }
#if os(iOS)
        guard let uiImage = UIImage(data: data) else { return Image(systemName: "photo") }
        return Image(uiImage: uiImage)
#else
        guard let nsImage = NSImage(data: data) else { return Image(systemName: "photo") }
        return Image(nsImage: nsImage)
#endif
    }

}

/// Cross-platform `PDFView` wrapper — PDFKit's `PDFView` is available on both iOS and macOS but
/// bridges into SwiftUI through different representable protocols per platform.
private struct AttachmentPDFView: View {

    let url: URL

    var body: some View {
        PDFKitRepresentable(url: url)
    }

}

#if os(iOS)
private struct PDFKitRepresentable: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.document = PDFDocument(url: url)
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document?.documentURL != url {
            uiView.document = PDFDocument(url: url)
        }
    }
}
#else
private struct PDFKitRepresentable: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.document = PDFDocument(url: url)
        return view
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
        if nsView.document?.documentURL != url {
            nsView.document = PDFDocument(url: url)
        }
    }
}
#endif
