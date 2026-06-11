import Foundation
import KeepersCore
import Testing

/// Invariant 2, schema half: tag data must never feed a ScoreCard — the
/// schema itself must stay free of tag/caption-derived fields.
@Suite("ScoreCard schema purity")
struct ScoreCardSchemaTests {
    @Test("ScoreCard has no tag- or caption-derived fields")
    func scoreCardHasNoTagFields() {
        // Arrange
        let card = ScoreCardBuilder.makeScoreCard(
            from: FrameAnalysis(
                frameID: FrameID("a.cr3"),
                faces: [],
                aestheticsScore: nil,
                isUtility: false,
                featurePrint: nil
            ),
            modelVersion: .VISION_ONLY_M1,
            scoredAt: Date(timeIntervalSince1970: 0)
        )

        // Act
        let fieldNames = Mirror(reflecting: card).children.compactMap(\.label)

        // Assert
        #expect(!fieldNames.isEmpty)
        for name in fieldNames {
            let lowered = name.lowercased()
            #expect(!lowered.contains("tag"), "ScoreCard field '\(name)' looks tag-derived")
            #expect(!lowered.contains("caption"), "ScoreCard field '\(name)' looks caption-derived")
        }
    }
}
