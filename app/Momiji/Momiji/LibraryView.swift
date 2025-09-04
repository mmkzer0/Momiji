//
//  LibraryView.swift
//  Momiji
//
//  Created by Lennart Kotzur on 04.09.25.
//

import SwiftUI
import UniformTypeIdentifiers
import ZIPFoundation

struct LibraryView: View {
    @State private var works: [Work] = []
    @State private var showImporter = false
    @State private var selectedWork: Work?
    @State private var selection: Work.ID?

    var body: some View {
        // Precompute the selected work to simplify the NavigationSplitView's detail closure
        let currentSelection: Work? = selection.flatMap { id in
            works.first(where: { $0.id == id })
        }

        NavigationSplitView {
            List(works, selection: $selection) { (w: Work) in
                WorkRow(work: w)
                    .tag(w.id)
            }
            .navigationTitle("Momiji")
            .toolbar {
                Button("Import") { showImporter = true }
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [UTType.zip, UTType.folder],
                onCompletion: handleImportResult(_:)
            )
        } detail: {
            if let w = currentSelection {
                ReaderHost(work: w)
            } else {
                ContentUnavailableView("Select a work", systemImage: "books.vertical")
            }
        }
        .task {
            if works.isEmpty {
                works = LibraryStore.shared.load()
            }
        }
        .onChange(of: works) {
            LibraryStore.shared.save(works)
        }
    }

    @MainActor
    private func handleImportResult(_ res: Result<URL, Error>) {
        switch res {
        case .success(let url):
            Task { await importURL(url) }
        case .failure(let error):
            print("Import failed:", error)
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
            w.pageCount = (try? countPages(at: local))
            works.append(w)
        } catch {
            print("Import failed:", error)
        }
    }
}

private func countPages(at url: URL) throws -> Int {
    if ["zip","cbz"].contains(url.pathExtension.lowercased()) {
        // Try both open paths (mirrors ZipArchiveReader)
        do {
            let a = try Archive(url: url, accessMode: .read)
            return a.compactMap { $0 }.filter { isImage($0.path) }.count
        } catch {
            let data = try Data(contentsOf: url)
            let a = try Archive(data: data, accessMode: .read)
            return a.compactMap { $0 }.filter { isImage($0.path) }.count
        }
    } else {
        let fm = FileManager.default
        let items = try fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        return items.filter { isImage($0.lastPathComponent) }.count
    }
}

private func isImage(_ name: String) -> Bool {
    [".jpg",".jpeg",".png",".webp",".bmp",".gif"].contains { name.lowercased().hasSuffix($0) }
}

private struct WorkRow: View {
    let work: Work

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(work.url.lastPathComponent)
                    .lineLimit(1)
                if let h = work.hash {
                    Text(h.prefix(12) + "…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                // If Work has a pageCount elsewhere (e.g., via extension), this will display it.
                // If not, this block will simply be skipped by the compiler due to optional binding failure at call sites.
                if let pc = work.pageCount {
                    Text("\(pc) pages")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}
