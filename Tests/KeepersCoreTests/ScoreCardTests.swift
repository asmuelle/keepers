import Foundation
import KeepersCore
import Testing

@Suite("ScoreCard builder")
struct ScoreCardTests {
    private let scoredAt = Date(timeIntervalSince1970: 1_750_000_000)

    private var sampleAnalysis: FrameAnalysis {
        FrameAnalysis(
            frameID: FrameID("IMG_0001.cr3"),
            faces: [
                FaceAnalysis(captureQuality: 0.8, leftEyeAspectRatio: 0.11, rightEyeAspectRatio: 0.11),
                FaceAnalysis(captureQuality: 0.6, leftEyeAspectRatio: 0.3, rightEyeAspectRatio: 0.3)
            ],
            aestheticsScore: 0.5,
            isUtility: false,
            featurePrint: FeaturePrintVector([0.1, 0.9])
        )
    }

    @Test("maps analysis fields and stamps the model version")
    func mapsFieldsAndStampsVersion() {
        // Act
        let card = ScoreCardBuilder.makeScoreCard(
            from: sampleAnalysis,
            modelVersion: .VISION_ONLY_M1,
            scoredAt: scoredAt
        )

        // Assert
        #expect(card.frameID == FrameID("IMG_0001.cr3"))
        #expect(card.modelVersion == .VISION_ONLY_M1)
        #expect(card.faceCount == 2)
        #expect(card.faces[0].isBlinking)
        #expect(!card.faces[1].isBlinking)
        #expect(card.compositeScore == CompositeScorer.compositeScore(for: sampleAnalysis))
        #expect(card.scoredAt == scoredAt)
    }

    @Test("same analysis + version + timestamp produce identical cards (invariant 6)")
    func deterministicBuild() {
        let first = ScoreCardBuilder.makeScoreCard(from: sampleAnalysis, modelVersion: .VISION_ONLY_M1, scoredAt: scoredAt)
        let second = ScoreCardBuilder.makeScoreCard(from: sampleAnalysis, modelVersion: .VISION_ONLY_M1, scoredAt: scoredAt)
        #expect(first == second)
    }

    @Test("rankerScore is recorded but does not alter the M1 Vision-only composite")
    func rankerScoreDoesNotAffectM1Composite() {
        let without = ScoreCardBuilder.makeScoreCard(from: sampleAnalysis, modelVersion: .VISION_ONLY_M1, scoredAt: scoredAt)
        let with = ScoreCardBuilder.makeScoreCard(
            from: sampleAnalysis,
            modelVersion: .VISION_ONLY_M1,
            rankerScore: 0.99,
            scoredAt: scoredAt
        )
        #expect(with.rankerScore == 0.99)
        #expect(with.compositeScore == without.compositeScore)
    }
}
