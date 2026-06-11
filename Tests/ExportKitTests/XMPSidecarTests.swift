import ExportKit
import Foundation
import Testing

@Suite("XMP sidecar serialization — golden files")
struct XMPSidecarTests {
    private func fixtureData(_ name: String) throws -> Data {
        let url = try #require(Bundle.module.url(
            forResource: name,
            withExtension: "xmp",
            subdirectory: "Fixtures"
        ))
        return try Data(contentsOf: url)
    }

    @Test("pick (★★★) serializes byte-identically to the golden file")
    func pickGoldenFile() throws {
        // Arrange
        let sidecar = try XMPSidecar(rating: 3)

        // Act
        let serialized = Data(sidecar.serialized().utf8)

        // Assert
        #expect(try serialized == fixtureData("pick-3-stars"))
    }

    @Test("reject (red label + ★) serializes byte-identically to the golden file")
    func rejectGoldenFile() throws {
        let sidecar = try XMPSidecar(rating: 1, label: .red)
        #expect(try Data(sidecar.serialized().utf8) == fixtureData("reject-red-1-star"))
    }

    @Test("maybe (unrated) serializes byte-identically to the golden file")
    func maybeGoldenFile() throws {
        let sidecar = try XMPSidecar(rating: 0)
        #expect(try Data(sidecar.serialized().utf8) == fixtureData("maybe-0-stars"))
    }

    @Test("ratings outside 0...5 throw")
    func invalidRatingThrows() {
        #expect(throws: ExportError.invalidStarRating(6)) { try XMPSidecar(rating: 6) }
        #expect(throws: ExportError.invalidStarRating(-1)) { try XMPSidecar(rating: -1) }
    }

    @Test("every label raw value is XML-attribute-safe, so no escaping pass is needed")
    func labelValuesAreXMLSafe() {
        let forbidden = CharacterSet(charactersIn: "&<>\"'")
        for label in XMPColorLabel.allCases {
            #expect(label.rawValue.rangeOfCharacter(from: forbidden) == nil)
        }
    }
}
