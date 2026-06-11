/// Per-face analysis results. `captureQuality` follows the platform contract:
/// comparable only for the SAME subject across a burst — never across people.
public struct FaceAnalysis: Sendable, Equatable {
    public let captureQuality: Double?
    public let leftEyeAspectRatio: Double?
    public let rightEyeAspectRatio: Double?

    public init(captureQuality: Double?, leftEyeAspectRatio: Double?, rightEyeAspectRatio: Double?) {
        self.captureQuality = captureQuality
        self.leftEyeAspectRatio = leftEyeAspectRatio
        self.rightEyeAspectRatio = rightEyeAspectRatio
    }

    /// A face is blinking when its lowest measured eye-aspect-ratio falls
    /// below the threshold. Unknown eyes (no landmarks) never count as blinks.
    public func isBlinking(threshold: Double = BlinkDefaults.EAR_THRESHOLD) -> Bool {
        let ratios = [leftEyeAspectRatio, rightEyeAspectRatio].compactMap(\.self)
        guard let lowest = ratios.min() else { return false }
        return lowest < threshold
    }
}

/// Everything one analyzer pass produces for one frame. Pure value type:
/// the entire downstream pipeline (composite score, clustering, ranking)
/// is a deterministic function of this struct (invariant 6).
public struct FrameAnalysis: Sendable, Equatable {
    public let frameID: FrameID
    public let faces: [FaceAnalysis]
    /// Aesthetics in the platform range −1…1; nil when unavailable (pre-iOS 18 gate).
    public let aestheticsScore: Double?
    public let isUtility: Bool
    public let featurePrint: FeaturePrintVector?
    /// Reserved: the Vision-only M1 path does not produce a separate sharpness signal.
    public let sharpness: Double?

    public init(
        frameID: FrameID,
        faces: [FaceAnalysis],
        aestheticsScore: Double?,
        isUtility: Bool,
        featurePrint: FeaturePrintVector?,
        sharpness: Double? = nil
    ) {
        self.frameID = frameID
        self.faces = faces
        self.aestheticsScore = aestheticsScore
        self.isUtility = isUtility
        self.featurePrint = featurePrint
        self.sharpness = sharpness
    }
}
