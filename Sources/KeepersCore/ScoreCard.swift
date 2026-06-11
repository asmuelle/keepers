import Foundation

/// Version stamp for the scoring pipeline. Re-scores under a new version APPEND
/// new cards — they never overwrite prior ones (invariant 6).
public struct ModelVersion: Sendable, Hashable, RawRepresentable, CustomStringConvertible {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// M1 pipeline: the four platform vision requests, no custom ranker.
    public static let VISION_ONLY_M1 = ModelVersion(rawValue: "vision-only-1")

    public var description: String {
        rawValue
    }
}

/// Per-face slice of a score card.
public struct FaceScore: Sendable, Equatable {
    public let captureQuality: Double?
    public let isBlinking: Bool

    public init(captureQuality: Double?, isBlinking: Bool) {
        self.captureQuality = captureQuality
        self.isBlinking = isBlinking
    }
}

/// One frame's scores under one model version (DESIGN.md data model).
/// Deliberately contains NO content-tag or caption fields: tags must never
/// feed scoring (invariant 2, asserted by schema test).
public struct ScoreCard: Sendable, Equatable {
    public let frameID: FrameID
    public let modelVersion: ModelVersion
    public let faceCount: Int
    public let faces: [FaceScore]
    public let aestheticsScore: Double?
    public let isUtility: Bool
    public let sharpness: Double?
    public let featurePrint: FeaturePrintVector?
    /// Custom Core ML ranker output — always nil in M1 (Vision-only pipeline).
    public let rankerScore: Double?
    public let compositeScore: Double
    public let scoredAt: Date

    public init(
        frameID: FrameID,
        modelVersion: ModelVersion,
        faceCount: Int,
        faces: [FaceScore],
        aestheticsScore: Double?,
        isUtility: Bool,
        sharpness: Double?,
        featurePrint: FeaturePrintVector?,
        rankerScore: Double?,
        compositeScore: Double,
        scoredAt: Date
    ) {
        self.frameID = frameID
        self.modelVersion = modelVersion
        self.faceCount = faceCount
        self.faces = faces
        self.aestheticsScore = aestheticsScore
        self.isUtility = isUtility
        self.sharpness = sharpness
        self.featurePrint = featurePrint
        self.rankerScore = rankerScore
        self.compositeScore = compositeScore
        self.scoredAt = scoredAt
    }
}

public enum ScoreCardBuilder {
    /// Pure builder: same analysis + version + timestamp ⇒ byte-identical card.
    /// M1 composite is Vision-only; `rankerScore` is recorded but NOT blended
    /// (the custom ranker and its blending policy are post-M1 by design).
    public static func makeScoreCard(
        from analysis: FrameAnalysis,
        modelVersion: ModelVersion,
        rankerScore: Double? = nil,
        scoredAt: Date
    ) -> ScoreCard {
        ScoreCard(
            frameID: analysis.frameID,
            modelVersion: modelVersion,
            faceCount: analysis.faces.count,
            faces: analysis.faces.map {
                FaceScore(captureQuality: $0.captureQuality, isBlinking: $0.isBlinking())
            },
            aestheticsScore: analysis.aestheticsScore,
            isUtility: analysis.isUtility,
            sharpness: analysis.sharpness,
            featurePrint: analysis.featurePrint,
            rankerScore: rankerScore,
            compositeScore: CompositeScorer.compositeScore(for: analysis),
            scoredAt: scoredAt
        )
    }
}
