//
//  LibraryStore.swift
//  Momiji
//
//  Created by Lennart Kotzur on 04.09.25.
//

import Foundation

struct WorkRecord : Codable {
    let filename: String
    let hash: String
    let pageCount: Int?
}

final class LibraryStore {
    static let shared = LibraryStore()
    
    private let fm = FileManager.default
    private let libDir: URL
    private let dbURL: URL
    
    init() {
        let docs = try! fm.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        libDir = docs.appendingPathComponent("Library",
                                             isDirectory: true)
        dbURL  = libDir
            .appendingPathComponent("_momiji_library.json",
                                    isDirectory: false)
        try? fm.createDirectory(at: libDir,
                                withIntermediateDirectories: true)
    }
    
    func load() -> [Work] {
        guard let data = try? Data(contentsOf: dbURL),
              let recs = try? JSONDecoder().decode([WorkRecord].self, from: data) else { return [] }
        return recs.compactMap { r in
            let url = libDir.appendingPathComponent(r.filename)
            guard fm.fileExists(atPath: url.path) else { return nil }
            return Work(url: url, hash: r.hash.isEmpty ? nil : r.hash, pageCount: r.pageCount)
        }
    }
    
    func save(_ works: [Work]) {
        let recs = works.map {
            WorkRecord(filename: $0.url.lastPathComponent,
                       hash: $0.hash ?? "", pageCount: $0.pageCount)
            }
                if let data = try? JSONEncoder().encode(recs) {
                    try? data.write(to: dbURL, options: .atomic)
            }
        }

    func libraryFolder() -> URL { libDir }
    
}
