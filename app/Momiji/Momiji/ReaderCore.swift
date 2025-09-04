//
//  ReaderCore.swift
//  Momiji
//
//  Created by Lennart Kotzur on 04.09.25.
//

import Foundation
import ZIPFoundation
import UIKit
import CryptoKit

protocol ArchiveReader {
    var pageCount: Int { get }
    func pageName(at index: Int) -> String
    func page(at index: Int) throws -> Data
}

private let supportedImageExtensions: Set<String> = ["jpg", "jpeg", "png", "webp", "bmp"]

private func isSupportedImagePath(_ path: String) -> Bool {
    let ext = (path as NSString).pathExtension.lowercased()
    return supportedImageExtensions.contains(ext)
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
    var pageCount: Int {
        switch impl {
        case .zip(let z): return z.pageCount
        case .folder(let f): return f.pageCount
        }
    }
    func pageName(at i: Int) -> String {
        switch impl {
        case .zip(let z): return z.pageName(at: i)
        case .folder(let f): return f.pageName(at: i)
        }
    }
    func page(at i: Int) throws -> Data {
        switch impl {
        case .zip(let z): return try z.page(at: i)
        case .folder(let f): return try f.page(at: i)
        }
    }
}

final class ZipArchiveReader: ArchiveReader {
    private let archive: Archive
    private let entries: [Entry]

    init(url: URL) throws {
        guard let a = Archive(url: url, accessMode: .read) else {
            throw NSError(domain: "zip", code: 1)
        }
        self.archive = a
        self.entries = a.compactMap { $0 }
            .filter { $0.type == .file && isSupportedImagePath($0.path) }
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
        self.files = items
            .filter { supportedImageExtensions.contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }
    var pageCount: Int { files.count }
    func pageName(at index: Int) -> String { files[index].lastPathComponent }
    func page(at index: Int) throws -> Data { try Data(contentsOf: files[index]) }
}

func importIntoLibrary(_ url: URL) throws -> URL {
    let fm = FileManager.default
    let docs = try fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    let lib = docs.appendingPathComponent("Library", isDirectory: true)
    try fm.createDirectory(at: lib, withIntermediateDirectories: true, attributes: nil)

    let dest = lib.appendingPathComponent(url.lastPathComponent, isDirectory: false)

    // If the source is already at the destination, avoid extra work.
    if url.standardizedFileURL == dest.standardizedFileURL {
        return dest
    }

    if fm.fileExists(atPath: dest.path) {
        try fm.removeItem(at: dest)
    }
    try fm.copyItem(at: url, to: dest)
    return dest
}

func sha256(url: URL) throws -> String {
    let handle = try FileHandle(forReadingFrom: url)
    defer { try? handle.close() }
    var hasher = SHA256()
    let chunkSize = 1 << 20 // 1 MiB

    while let data = try handle.read(upToCount: chunkSize), !data.isEmpty {
        hasher.update(data: data)
    }

    return hasher.finalize().map { String(format: "%02x", $0) }.joined()
}
