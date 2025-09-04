//
//  ReaderCore.swift
//  Momiji
//
//  Created by Lennart Kotzur on 04.09.25.
//

import Foundation
import ZIPFoundation
import UIKit

protocol ArchiveReader {
    var pageCount: Int { get }
    func pageName(at index: Int) -> String
    func page(at index: Int) throws -> Data
}

struct ZipOrFolderReader: ArchiveReader {
    private enum Impl { case zip(ZipArchiveReader), folder(FolderReader) }
    private let impl: Impl

    init(url: URL) throws {
        if ["zip","cbz"].contains(url.pathExtension.lowercased()) {
            self.impl = .zip(try ZipArchiveReader(url: url))
        } else {
            self.impl = .folder(FolderReader(url: url))
        }
    }
    var pageCount: Int { switch impl { case .zip(let z): z.pageCount; case .folder(let f): f.pageCount } }
    func pageName(at i: Int) -> String { switch impl { case .zip(let z): z.pageName(at: i); case .folder(let f): f.pageName(at: i) } }
    func page(at i: Int) throws -> Data { switch impl { case .zip(let z): try z.page(at: i); case .folder(let f): try f.page(at: i) } }
}

final class ZipArchiveReader: ArchiveReader {
    private let archive: Archive
    private let entries: [Entry]

    init(url: URL) throws {
        guard let a = Archive(url: url, accessMode: .read) else { throw NSError(domain: "zip", code: 1) }
        self.archive = a
        self.entries = a.compactMap { $0 }
            .filter { $0.type == .file && $0.path.lowercased().hasSuffix(anyOf: [".jpg",".jpeg",".png",".webp",".bmp"]) }
            .sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
    }
    var pageCount: Int { entries.count }
    func pageName(at index: Int) -> String { entries[index].path }
    func page(at index: Int) throws -> Data {
        var data = Data()
        try archive.extract(entries[index]) { data.append($0) }
        return data
    }
}

struct FolderReader: ArchiveReader {
    private let files: [URL]
    init(url: URL) {
        let fm = FileManager.default
        let items = (try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)) ?? []
        self.files = items.filter { ["jpg","jpeg","png","webp","bmp"].contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }
    var pageCount: Int { files.count }
    func pageName(at index: Int) -> String { files[index].lastPathComponent }
    func page(at index: Int) throws -> Data { try Data(contentsOf: files[index]) }
}

private extension String {
    func hasSuffix(anyOf exts: [String]) -> Bool { exts.contains { self.hasSuffix($0) } }
}
