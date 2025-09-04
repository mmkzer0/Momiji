//
//  ReaderView.swift
//  Momiji
//
//  Created by Lennart Kotzur on 04.09.25.
//

import SwiftUI

struct ReaderView: View {
    let reader: ArchiveReader
    let title: String
    @State private var index = 0

    var body: some View {
        TabView(selection: $index) {
            ForEach(0..<reader.pageCount, id: \.self) { i in
                PageImage(reader: reader, index: i).tag(i).ignoresSafeArea()
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PageImage: View {
    let reader: ArchiveReader
    let index: Int
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let img = image { Image(uiImage: img).resizable().scaledToFit() }
            else { ProgressView() }
        }
        .task {
            if image == nil, let data = try? reader.page(at: index), let ui = UIImage(data: data) {
                image = ui
            }
        }
    }
}
