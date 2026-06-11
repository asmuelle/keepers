import Foundation
import KeepersCore
import Testing

@Suite("Frame types")
struct FrameTypesTests {
    @Test("maps supported extensions case-insensitively")
    func extensionMapping() {
        #expect(RawFileType(fileExtension: "CR3") == .cr3)
        #expect(RawFileType(fileExtension: "nef") == .nef)
        #expect(RawFileType(fileExtension: "ARW") == .arw)
        #expect(RawFileType(fileExtension: "raf") == .raf)
        #expect(RawFileType(fileExtension: "DNG") == .dng)
        #expect(RawFileType(fileExtension: "jpg") == .jpeg)
        #expect(RawFileType(fileExtension: "JPEG") == .jpeg)
    }

    @Test("rejects unsupported extensions")
    func unsupportedExtensions() {
        #expect(RawFileType(fileExtension: "txt") == nil)
        #expect(RawFileType(fileExtension: "") == nil)
        #expect(RawFileType(fileExtension: "heic") == nil)
    }

    @Test("isRaw distinguishes RAW formats from JPEG")
    func isRawFlag() {
        #expect(RawFileType.cr3.isRaw)
        #expect(!RawFileType.jpeg.isRaw)
    }

    @Test("FrameID compares lexicographically for stable tie-breaks")
    func frameIDComparable() {
        #expect(FrameID("a.cr3") < FrameID("b.cr3"))
        #expect(!(FrameID("b.cr3") < FrameID("a.cr3")))
    }

    @Test("session status transition returns a new value")
    func sessionWithStatus() throws {
        let session = try Session(
            id: #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001")),
            name: "Test",
            createdAt: Date(timeIntervalSince1970: 0),
            frameCount: 10,
            status: .ingesting,
            modelVersion: .VISION_ONLY_M1
        )
        let scoring = session.with(status: .scoring)
        #expect(session.status == .ingesting)
        #expect(scoring.status == .scoring)
        #expect(scoring.id == session.id)
    }
}
