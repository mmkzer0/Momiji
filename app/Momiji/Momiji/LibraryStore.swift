//
//  LibraryStore.swift
//  Momiji
//
//  Created by Lennart Kotzur on 04.09.25.
//

import Foundation

// record struct for works with basic metadata
struct WorkRecord : Codable {
    let filename: String
    let hash: String
    let pageCount: Int?
}

// for persistent fs storage
final class LibraryStore {
    static let shared = LibraryStore()
    
    // need a fm as well as a lib and db url
    private let fm = FileManager.default
    private let libDir: URL
    private let dbURL: URL
    
    // init internal paths
    init() {
        let docs = try! fm.url(             // the try! potentially crashes on no dir?
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
    
    // try loading works from our json file
    func load() -> [Work] {
        guard let data = try? Data(contentsOf: dbURL),
              let recs = try? JSONDecoder().decode([WorkRecord].self, from: data) else {
            return []
        }
        return recs.compactMap { r in
            let url = libDir.appendingPathComponent(r.filename)
            guard fm.fileExists(atPath: url.path) else { return nil }
            return Work(
                url: url,
                hash: r.hash.isEmpty ? nil : r.hash,
                pageCount: r.pageCount
            )
        }
    }
    
    // try saving works to json
    func save(_ works: [Work]) {
        let recs = works.map {
            WorkRecord(filename: $0.url.lastPathComponent,
                       hash: $0.hash ?? "", pageCount: $0.pageCount)
        }
        if let data = try? JSONEncoder().encode(recs) {
            try? data.write(to: dbURL, options: .atomic)
        }
    }
    
    // small helper to grab libFolder
    func libraryFolder() -> URL { libDir }
    
}
