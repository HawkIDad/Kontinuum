// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  CanvasFileDocument.swift
//  NoteBytez
//

import SwiftUI
import UniformTypeIdentifiers

/// Minimal `FileDocument` wrapper so `CanvasBoardView` can hand a board's JSON Canvas text to
/// `.fileExporter(document:)` — mirrors `MarkdownFileDocument.swift` exactly (write-only in
/// practice; the app imports `.canvas` files through `CanvasBoardListView`'s `.fileImporter`
/// instead of the system Open panel).
struct CanvasFileDocument: FileDocument {

    static var readableContentTypes: [UTType] { [UTType(filenameExtension: "canvas") ?? .json] }

    var text: String

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents, let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }

}
