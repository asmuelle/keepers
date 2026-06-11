import Foundation

public enum Verdict: String, Sendable, CaseIterable {
    case pick
    case reject
    case maybe
}

public enum DecisionSource: String, Sendable {
    case auto
    case user
}

public enum DecisionError: Error, Equatable {
    case invalidStarRating(Int)
}

/// One culling decision. Decisions are immutable training signal: new decisions
/// SUPERSEDE old ones in the log — nothing is ever mutated or deleted.
public struct CullDecision: Sendable, Equatable {
    public static let STAR_RATING_RANGE = 0 ... 5

    public let frameID: FrameID
    public let verdict: Verdict
    public let starRating: Int
    public let decidedBy: DecisionSource
    public let decidedAt: Date

    public init(
        frameID: FrameID,
        verdict: Verdict,
        starRating: Int,
        decidedBy: DecisionSource,
        decidedAt: Date
    ) throws {
        guard Self.STAR_RATING_RANGE.contains(starRating) else {
            throw DecisionError.invalidStarRating(starRating)
        }
        self.frameID = frameID
        self.verdict = verdict
        self.starRating = starRating
        self.decidedBy = decidedBy
        self.decidedAt = decidedAt
    }
}

/// Append-only decision log. `appending` returns a NEW log — the original is
/// untouched, preserving every superseded decision as training signal.
public struct DecisionLog: Sendable, Equatable {
    public let entries: [CullDecision]

    public init(entries: [CullDecision] = []) {
        self.entries = entries
    }

    public func appending(_ decision: CullDecision) -> DecisionLog {
        DecisionLog(entries: entries + [decision])
    }

    /// The decision currently in force for a frame: the most recently appended.
    public func latestDecision(for frameID: FrameID) -> CullDecision? {
        entries.last { $0.frameID == frameID }
    }

    /// Latest decision per frame, by append order.
    public func latestDecisions() -> [FrameID: CullDecision] {
        entries.reduce(into: [:]) { $0[$1.frameID] = $1 }
    }
}
