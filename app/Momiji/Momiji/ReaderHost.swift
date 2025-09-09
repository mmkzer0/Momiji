//
//  ReaderHost.swift
//  Momiji
//
//  Created by Lennart Kotzur on 04.09.25.
//

import Foundation
import SwiftUI

struct ReaderHost: View {
    let work: Work
    @State private var reader: (any ArchiveReader)?
    @State private var error: String?

    var body: some View {
        Group {
            if let r = reader {
                ReaderView(reader: r, title: work.url.lastPathComponent, workID: work.id)
            } else if let e = error {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle").font(.largeTitle)
                    Text("Failed to open").font(.headline)
                    Text(e).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }.padding()
            } else {
                ProgressView()      // shows until reader is ready or error thrown
            }
        }
        .task(id: work.id) {
            reader = nil
            error = nil
            do { reader = try ZipOrFolderReader(url: work.url) } catch {
                self.error = error.localizedDescription
            }
        }
        .navigationTitle(work.url.lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @MainActor
    private func load() {
        do {
            print("Opening:", work.url.path) // debug
            reader = try ZipOrFolderReader(url: work.url)
        } catch {
            self.error = error.localizedDescription
            print("Reader open failed:", error)
        }
    }
    
    
}
