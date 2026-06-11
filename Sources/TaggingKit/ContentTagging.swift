import KeepersCore

/// Optional on-device content tag (post-M2 scope; DESIGN.md deliberate cut).
public struct ContentTag: Sendable, Equatable {
    public let label: String
    public let confidence: Double

    public init(label: String, confidence: Double) {
        self.label = label
        self.confidence = confidence
    }
}

/// Boundary for optional platform-AI content tags. Scaffolded only — the v1
/// product ships without it. This module must NEVER be imported by the scoring
/// or ranking modules (invariant 2, grep-enforced in InvariantTests), and tag
/// data must never feed a ScoreCard.
public protocol ContentTagging: Sendable {
    func tags(for preview: PreviewData) async throws -> [ContentTag]
}

/// Placeholder implementation: tagging is out of scope for v1.
public struct NoOpTagger: ContentTagging {
    public init() {}

    public func tags(for _: PreviewData) async throws -> [ContentTag] {
        []
    }
}
