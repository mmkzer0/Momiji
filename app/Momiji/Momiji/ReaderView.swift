//
//  ReaderView.swift
//  Momiji
//
//  Created by Lennart Kotzur on 04.09.25.
//

import SwiftUI

struct ReaderView: View {
    let reader: any ArchiveReader
    let title: String
    let workID: UUID                // use to detect work change
    @State private var index = 0

    // Compose unique page identities that include the current work
    private var pageKeys: [PageKey] {
        (0..<reader.pageCount).map { PageKey(workID: workID, index: $0) }
    }

    var body: some View {
        TabView(selection: $index) {
            ForEach(pageKeys) { key in
                PageImage(reader: reader, workID: key.workID, index: key.index)
                    .tag(key.index)
                    .ignoresSafeArea()
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        // Recreate the entire TabView when the work changes
        .id(workID)
        // Reset to first page when the work changes
        .task(id: workID) { index = 0 }
    }
}

private struct PageKey: Identifiable, Hashable {
    let workID: UUID
    let index: Int
    var id: String { "\(workID.uuidString)#\(index)" }
}

private struct PageImage: View {
    let reader: any ArchiveReader
    let workID: UUID
    let index: Int
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView()
            }
        }
        // Clear any stale image immediately when the work changes.
        .onChange(of: workID) {
            image = nil
        }
        // Load whenever the work or the page index changes.
        .task(id: taskKey) {
            // Clear before loading to avoid showing a stale image during the render pass.
            image = nil
            if let data = try? reader.page(at: index),
               let ui = UIImage(data: data) {
                image = ui
            }
        }
    }

    // Unique key driving the task lifecycle
    private var taskKey: String { "\(workID.uuidString)-\(index)" }
}
