import KeepersCore
import TaggingKit
import Testing

@Suite("TaggingKit boundary (post-M2 scaffold)")
struct TaggingKitTests {
    @Test("NoOpTagger produces no tags — tagging is out of scope for v1")
    func noOpTaggerIsEmpty() async throws {
        let preview = PreviewData(imageData: .init(), pixelWidth: 1, pixelHeight: 1)
        let tags = try await NoOpTagger().tags(for: preview)
        #expect(tags.isEmpty)
    }
}
