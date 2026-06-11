import KeepersCore

/// Deterministic stand-in for the Vision pipeline, seeded from the frame path
/// via FNV-1a: same frame ⇒ same analysis on every run and every machine.
/// This is what keeps `swift test` hermetic (no model, no network, no device)
/// and what the demo session renders.
public struct MockFrameAnalyzer: FrameAnalyzing {
    static let MAX_FACES = 3
    static let BLINK_PROBABILITY = 0.2
    static let UTILITY_PROBABILITY = 0.05
    static let CLOSED_EYE_EAR = 0.11
    static let FEATURE_PRINT_DIMENSIONS = 8

    public init() {}

    public func analyze(frame: Frame, preview _: PreviewData) async throws -> FrameAnalysis {
        let key = frame.relativePath
        return FrameAnalysis(
            frameID: frame.id,
            faces: makeFaces(key: key),
            aestheticsScore: -1 + 2 * StableHash.unit(key, salt: "aesthetics"),
            isUtility: StableHash.unit(key, salt: "utility") < Self.UTILITY_PROBABILITY,
            featurePrint: makePrint(key: key)
        )
    }

    private func makeFaces(key: String) -> [FaceAnalysis] {
        let faceCount = Int(StableHash.fnv1a("faces:" + key) % UInt64(Self.MAX_FACES))
        return (0 ..< faceCount).map { index in
            let salt = "face\(index)"
            let isBlinking = StableHash.unit(key, salt: salt + ":blink") < Self.BLINK_PROBABILITY
            let openEAR = 0.24 + 0.12 * StableHash.unit(key, salt: salt + ":ear")
            let ear = isBlinking ? Self.CLOSED_EYE_EAR : openEAR
            return FaceAnalysis(
                captureQuality: StableHash.unit(key, salt: salt + ":quality"),
                leftEyeAspectRatio: ear,
                rightEyeAspectRatio: ear
            )
        }
    }

    private func makePrint(key: String) -> FeaturePrintVector {
        FeaturePrintVector(
            (0 ..< Self.FEATURE_PRINT_DIMENSIONS).map { StableHash.unit(key, salt: "print\($0)") }
        )
    }
}
