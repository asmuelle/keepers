/// Weights for the Vision-only composite score (M1). The composite must stay a
/// TOTAL function: when a signal is missing (e.g. aesthetics on pre-iOS 18),
/// its weight is redistributed — never a crash, never a hole in the ranking.
public struct CompositeWeights: Sendable, Equatable {
    public let aesthetics: Double
    public let faceQuality: Double
    /// Strength of the blink penalty multiplier (0 = ignore blinks, 1 = a fully
    /// blinking frame scores 0).
    public let blinkPenalty: Double
    /// Multiplier applied when the platform flags the image as a utility shot
    /// (screenshots, documents) — those should sink, not win.
    public let utilityPenaltyFactor: Double

    public static let DEFAULT = CompositeWeights(
        aesthetics: 0.55,
        faceQuality: 0.45,
        blinkPenalty: 0.6,
        utilityPenaltyFactor: 0.25
    )

    /// Score used when no signal at all is available — keeps the function total.
    public static let NEUTRAL_BASELINE = 0.5

    public init(aesthetics: Double, faceQuality: Double, blinkPenalty: Double, utilityPenaltyFactor: Double) {
        self.aesthetics = aesthetics
        self.faceQuality = faceQuality
        self.blinkPenalty = blinkPenalty
        self.utilityPenaltyFactor = utilityPenaltyFactor
    }
}

public enum CompositeScorer {
    /// Deterministic composite in [0, 1] (invariant 6): a pure function of the
    /// analysis value — same analysis ⇒ same score, on every run.
    public static func compositeScore(
        for analysis: FrameAnalysis,
        weights: CompositeWeights = .DEFAULT
    ) -> Double {
        let aesthetics = analysis.aestheticsScore.map { ($0 + 1) / 2 }
        let qualities = analysis.faces.compactMap(\.captureQuality)
        let faceQuality = qualities.isEmpty ? nil : qualities.reduce(0, +) / Double(qualities.count)

        let base = weightedBase(aesthetics: aesthetics, faceQuality: faceQuality, weights: weights)
        let blinkAdjusted = base * (1 - weights.blinkPenalty * blinkFraction(of: analysis.faces))
        let utilityAdjusted = analysis.isUtility ? blinkAdjusted * weights.utilityPenaltyFactor : blinkAdjusted
        return min(max(utilityAdjusted, 0), 1)
    }

    /// Weighted mean of the available signals; missing signals redistribute weight.
    static func weightedBase(aesthetics: Double?, faceQuality: Double?, weights: CompositeWeights) -> Double {
        switch (aesthetics, faceQuality) {
        case let (.some(aesthetic), .some(face)):
            (weights.aesthetics * aesthetic + weights.faceQuality * face)
                / (weights.aesthetics + weights.faceQuality)
        case let (.some(aesthetic), .none):
            aesthetic
        case let (.none, .some(face)):
            face
        case (.none, .none):
            CompositeWeights.NEUTRAL_BASELINE
        }
    }

    /// Fraction of detected faces currently blinking; 0 when no faces.
    static func blinkFraction(of faces: [FaceAnalysis]) -> Double {
        guard !faces.isEmpty else { return 0 }
        let blinking = faces.count(where: { $0.isBlinking() })
        return Double(blinking) / Double(faces.count)
    }
}
