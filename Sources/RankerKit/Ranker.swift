import KeepersCore

/// Boundary for the custom Core ML aesthetic ranker + per-photographer
/// personalization head. M1 ships Vision-only composite scores (DESIGN.md),
/// so the only implementation today is an explicit no-op — the protocol exists
/// so the scheduler and UI never need to change when the real model lands.
public protocol RankerScoring: Sendable {
    /// Learned score in 0...1, or nil when no model is loaded.
    func rankerScore(for analysis: FrameAnalysis) -> Double?
}

/// M1 placeholder: no custom model, no personalization — deliberately nil.
public struct NoOpRanker: RankerScoring {
    public init() {}

    public func rankerScore(for _: FrameAnalysis) -> Double? {
        nil
    }
}
