import Foundation
import IngestKit
import Testing

@Suite("Mock preview extraction")
struct PreviewExtractionTests {
    @Test("is deterministic for the same file")
    func deterministicForSameFile() throws {
        let extractor = MockPreviewExtractor()
        let url = URL(fileURLWithPath: "/Volumes/CARD/IMG_0001.cr3")
        #expect(try extractor.extractEmbeddedPreview(from: url) == extractor.extractEmbeddedPreview(from: url))
    }

    @Test("different files yield different payloads")
    func differsAcrossFiles() throws {
        let extractor = MockPreviewExtractor()
        let first = try extractor.extractEmbeddedPreview(from: URL(fileURLWithPath: "/a.cr3"))
        let second = try extractor.extractEmbeddedPreview(from: URL(fileURLWithPath: "/b.cr3"))
        #expect(first.imageData != second.imageData)
    }

    @Test("reports the mock working size")
    func reportsWorkingSize() throws {
        let preview = try MockPreviewExtractor().extractEmbeddedPreview(from: URL(fileURLWithPath: "/a.cr3"))
        #expect(preview.pixelWidth == MockPreviewExtractor.MOCK_PIXEL_WIDTH)
        #expect(preview.pixelHeight == MockPreviewExtractor.MOCK_PIXEL_HEIGHT)
    }
}
