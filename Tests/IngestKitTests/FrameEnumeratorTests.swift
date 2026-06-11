import Foundation
import IngestKit
import KeepersCore
import Testing

/// Pure listing stub — no file system involved.
private struct StubListing: DirectoryListing {
    let names: [String]

    func fileURLs(inDirectory directory: URL) throws -> [URL] {
        names.map { directory.appendingPathComponent($0) }
    }
}

@Suite("Frame enumeration")
struct FrameEnumeratorTests {
    private let directory = URL(fileURLWithPath: "/Volumes/CARD/DCIM")

    @Test("filters to supported camera formats and sorts by name")
    func filtersAndSorts() throws {
        // Arrange
        let listing = StubListing(names: [
            "IMG_0002.CR3", "IMG_0001.cr3", "IMG_0003.NEF", "notes.txt",
            "IMG_0004.arw", "IMG_0005.jpg", "IMG_0006.dng", "IMG_0007.raf"
        ])

        // Act
        let frames = try FrameEnumerator(listing: listing).frames(inDirectory: directory)

        // Assert
        #expect(frames.map(\.relativePath) == [
            "IMG_0001.cr3", "IMG_0002.CR3", "IMG_0003.NEF", "IMG_0004.arw",
            "IMG_0005.jpg", "IMG_0006.dng", "IMG_0007.raf"
        ])
        #expect(frames[0].fileType == .cr3)
        #expect(frames[4].fileType == .jpeg)
    }

    @Test("hidden files are skipped even if their extension matches")
    func skipsHiddenFiles() throws {
        let listing = StubListing(names: [".hidden.cr3", "IMG_0001.cr3"])
        let frames = try FrameEnumerator(listing: listing).frames(inDirectory: directory)
        #expect(frames.map(\.relativePath) == ["IMG_0001.cr3"])
    }

    @Test("empty directory yields an empty session")
    func emptyDirectory() throws {
        let frames = try FrameEnumerator(listing: StubListing(names: [])).frames(inDirectory: directory)
        #expect(frames.isEmpty)
    }

    @Test("real FileManager listing enumerates a fixture directory")
    func realFileManagerListing() throws {
        // Arrange: a unique temp dir standing in for a card folder
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("keepers-enum-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        for name in ["B.cr3", "A.nef", "ignore.txt"] {
            try Data("stub".utf8).write(to: tempDirectory.appendingPathComponent(name))
        }

        // Act
        let frames = try FrameEnumerator().frames(inDirectory: tempDirectory)

        // Assert
        #expect(frames.map(\.relativePath) == ["A.nef", "B.cr3"])
    }
}
