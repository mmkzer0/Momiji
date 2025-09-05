import Foundation
import Testing
@testable import Momiji

struct ReaderCoreTests {
    @Test func testSHA256Consistent() async throws {
        let fm = FileManager.default
        let tmp = fm.temporaryDirectory.appendingPathComponent("hash-test.txt")
        try "Hello, world!".data(using: .utf8)!.write(to: tmp)
        defer { try? fm.removeItem(at: tmp) }
        let h = try sha256(url: tmp)
        #expect(h == "315f5bdb76d078c43b8ac0064e4a0164612b1fce77c869345bfc94c75894edd3")
    }

    @Test func testImportIntoLibraryCopiesFile() async throws {
        let fm = FileManager.default
        let source = fm.temporaryDirectory.appendingPathComponent("source.txt")
        try "data".data(using: .utf8)!.write(to: source)
        defer { try? fm.removeItem(at: source) }

        let dest = try importIntoLibrary(source)
        #expect(dest != source)
        #expect(fm.fileExists(atPath: dest.path))
        try? fm.removeItem(at: dest)
    }

    @Test func testLibraryStoreRoundtrip() async throws {
        let store = LibraryStore()
        let fm = FileManager.default
        let lib = store.libraryFolder()
        let file = lib.appendingPathComponent("work.txt")
        try "work".data(using: .utf8)!.write(to: file)
        defer {
            try? fm.removeItem(at: file)
            try? fm.removeItem(at: lib.appendingPathComponent("_momiji_library.json"))
        }

        let work = Work(url: file, hash: "abcd", pageCount: 2)
        store.save([work])
        let loaded = store.load()
        #expect(loaded.count == 1)
        #expect(loaded[0].url.lastPathComponent == "work.txt")
        #expect(loaded[0].hash == "abcd")
        #expect(loaded[0].pageCount == 2)
    }
}

