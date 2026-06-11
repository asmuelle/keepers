import KeepersCore
import Testing

@Suite("Composite score — total, deterministic, golden values")
struct CompositeScoreTests {
    private func analysis(
        faces: [FaceAnalysis] = [],
        aesthetics: Double? = nil,
        isUtility: Bool = false
    ) -> FrameAnalysis {
        FrameAnalysis(
            frameID: FrameID("test.cr3"),
            faces: faces,
            aestheticsScore: aesthetics,
            isUtility: isUtility,
            featurePrint: nil
        )
    }

    private func openFace(quality: Double) -> FaceAnalysis {
        FaceAnalysis(captureQuality: quality, leftEyeAspectRatio: 0.3, rightEyeAspectRatio: 0.3)
    }

    private func blinkingFace(quality: Double) -> FaceAnalysis {
        FaceAnalysis(captureQuality: quality, leftEyeAspectRatio: 0.11, rightEyeAspectRatio: 0.11)
    }

    @Test("all signals present: golden value")
    func fullSignalsGoldenValue() {
        // Arrange: aesthetics raw 0.5 → 0.75 normalized; face qualities mean 0.7
        let input = analysis(
            faces: [openFace(quality: 0.8), openFace(quality: 0.6)],
            aesthetics: 0.5
        )

        // Act
        let score = CompositeScorer.compositeScore(for: input)

        // Assert: (0.55·0.75 + 0.45·0.7) / 1.0 = 0.7275
        #expect(abs(score - 0.7275) < 1e-9)
    }

    @Test("half the faces blinking applies the blink penalty")
    func blinkPenaltyGoldenValue() {
        // Arrange: same base as above, one of two faces blinking
        let input = analysis(
            faces: [blinkingFace(quality: 0.8), openFace(quality: 0.6)],
            aesthetics: 0.5
        )

        // Act
        let score = CompositeScorer.compositeScore(for: input)

        // Assert: 0.7275 × (1 − 0.6·0.5) = 0.50925
        #expect(abs(score - 0.50925) < 1e-9)
    }

    @Test("no faces: full weight goes to aesthetics")
    func noFacesRedistributesToAesthetics() {
        let score = CompositeScorer.compositeScore(for: analysis(aesthetics: 0.0))
        #expect(abs(score - 0.5) < 1e-9) // raw 0 → normalized 0.5
    }

    @Test("no aesthetics (pre-iOS 18 gate): full weight goes to face quality")
    func noAestheticsRedistributesToFaces() {
        let score = CompositeScorer.compositeScore(for: analysis(faces: [openFace(quality: 1.0)]))
        #expect(abs(score - 1.0) < 1e-9)
    }

    @Test("no signals at all: neutral baseline, never a crash")
    func totalWithNoSignals() {
        let score = CompositeScorer.compositeScore(for: analysis())
        #expect(score == CompositeWeights.NEUTRAL_BASELINE)
    }

    @Test("utility frames sink")
    func utilityPenalty() {
        // Arrange: perfect aesthetics, flagged as utility
        let input = analysis(aesthetics: 1.0, isUtility: true)

        // Act
        let score = CompositeScorer.compositeScore(for: input)

        // Assert: 1.0 × 0.25
        #expect(abs(score - 0.25) < 1e-9)
    }

    @Test("result is clamped to [0, 1] even under extreme custom weights")
    func clamping() {
        let weights = CompositeWeights(
            aesthetics: 0.5,
            faceQuality: 0.5,
            blinkPenalty: 2.0,
            utilityPenaltyFactor: 0.25
        )
        let input = analysis(faces: [blinkingFace(quality: 1.0)], aesthetics: 1.0)
        let score = CompositeScorer.compositeScore(for: input, weights: weights)
        #expect(score == 0)
    }

    @Test("same analysis twice yields the identical score (invariant 6)")
    func deterministic() {
        let input = analysis(faces: [openFace(quality: 0.42)], aesthetics: 0.123)
        #expect(
            CompositeScorer.compositeScore(for: input) == CompositeScorer.compositeScore(for: input)
        )
    }
}
