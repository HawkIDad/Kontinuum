// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  MarkdownFileDocument.swift
//  NoteBytez
//

import SwiftUI
import UniformTypeIdentifiers

/// Minimal `FileDocument` wrapper so `DocumentView` can hand a note's raw content to
/// SwiftUI's `.fileExporter(document:)` for per-note export — write-only in practice (the
/// app never opens `.md` files through the system's Open panel), but `FileDocument` requires
/// both directions.
struct MarkdownFileDocument: FileDocument {

    static var readableContentTypes: [UTType] { [.plainText] }

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
