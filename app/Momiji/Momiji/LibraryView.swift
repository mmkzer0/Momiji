//
//  LibraryView.swift
//  Momiji
//
//  Created by Lennart Kotzur on 04.09.25.
//

import SwiftUI
import UniformTypeIdentifiers


struct LibraryView: View {
    @State private var works: [Work] = []
    @State private var showImporter = false
    @State private var selectedWork: Work?

    var body: some View {
        NavigationSplitView {
            List(works) { w in
                Button {
                    selectedWork = w
                } label: {
                    VStack(alignment: .leading) {
                        Text(w.url.lastPathComponent).lineLimit(1)
                        if let h = w.hash {
                            Text(h.prefix(12) + "…").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Momiji")
            .toolbar { Button("Import") { showImporter = true } }
            .fileImporter(isPresented: $showImporter,
                          allowedContentTypes: [.zip, .folder]) { res in
                if case let .success(url) = res {
                    Task { await importURL(url) }
                }
            }
        } detail: {
            if let w = selectedWork, let reader = try? ZipOrFolderReader(url: w.url) {
                ReaderView(reader: reader, title: w.url.lastPathComponent)
            } else {
                ContentUnavailableView("Select a work", systemImage: "books.vertical")
            }
        }
    }

    @MainActor
    private func importURL(_ url: URL) async {
        do {
                // Security-scoped access just for the copy step
                guard url.startAccessingSecurityScopedResource() else { throw CocoaError(.fileReadNoPermission) }
                defer { url.stopAccessingSecurityScopedResource() }

                let local = try importIntoLibrary(url)
                let h = try sha256(url: local)

                var w = Work(url: local)
                w.hash = h
                works.append(w)
            } catch {
                print("Import failed:", error)
            }
    }
}
