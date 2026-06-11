import ExportKit
import Foundation
import Testing

@Suite("Sidecar writer — non-destructive by construction (invariant 4)")
struct SidecarWriterTests {
    /// Creates an isolated stand-in for a card folder with one fake RAW in it.
    private func makeCardFolder() throws -> (directory: URL, rawURL: URL, rawBytes: Data) {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("keepers-export-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let rawURL = directory.appendingPathComponent("IMG_0001.cr3")
        let rawBytes = Data("fake-raw-bytes-do-not-touch".utf8)
        try rawBytes.write(to: rawURL)
        return (directory, rawURL, rawBytes)
    }

    @Test("writes the sidecar next to the RAW with Lightroom pairing semantics")
    func writesSidecarNextToRaw() throws {
        // Arrange
        let (directory, rawURL, _) = try makeCardFolder()
        defer { try? FileManager.default.removeItem(at: directory) }
        let sidecar = try XMPSidecar(rating: 3)

        // Act
        let written = try SidecarWriter().write(sidecar, forRawAt: rawURL)

        // Assert
        #expect(written.lastPathComponent == "IMG_0001.xmp")
        #expect(try Data(contentsOf: written) == Data(sidecar.serialized().utf8))
    }

    @Test("the original RAW bytes are untouched after writing")
    func originalIsNeverModified() throws {
        // Arrange
        let (directory, rawURL, rawBytes) = try makeCardFolder()
        defer { try? FileManager.default.removeItem(at: directory) }

        // Act
        try SidecarWriter().write(XMPSidecar(rating: 1, label: .red), forRawAt: rawURL)

        // Assert
        #expect(try Data(contentsOf: rawURL) == rawBytes)
    }

    @Test("re-export overwrites only the sidecar")
    func reExportOverwritesSidecar() throws {
        // Arrange
        let (directory, rawURL, rawBytes) = try makeCardFolder()
        defer { try? FileManager.default.removeItem(at: directory) }
        let writer = SidecarWriter()

        // Act: first export rejects, second export picks
        try writer.write(XMPSidecar(rating: 1, label: .red), forRawAt: rawURL)
        let written = try writer.write(XMPSidecar(rating: 3), forRawAt: rawURL)

        // Assert
        #expect(try Data(contentsOf: written) == Data(XMPSidecar(rating: 3).serialized().utf8))
        #expect(try Data(contentsOf: rawURL) == rawBytes)
    }

    @Test("refuses to write when the destination would collide with the source file")
    func refusesNonSidecarDestination() throws {
        // Arrange: a source file that is itself named .xmp
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("keepers-export-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let collidingURL = directory.appendingPathComponent("IMG_0001.xmp")

        // Act / Assert
        #expect(throws: ExportError.destinationIsNotSidecar("IMG_0001.xmp")) {
            try SidecarWriter().write(XMPSidecar(rating: 3), forRawAt: collidingURL)
        }
    }

    @Test("sidecarURL maps RAW names to .xmp siblings")
    func sidecarURLMapping() {
        let writer = SidecarWriter()
        let url = writer.sidecarURL(forRawAt: URL(fileURLWithPath: "/Volumes/CARD/DCIM/IMG_2042.NEF"))
        #expect(url.path == "/Volumes/CARD/DCIM/IMG_2042.xmp")
    }
}
