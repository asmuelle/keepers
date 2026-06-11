import Foundation
import KeepersCore

/// Storage seam for sessions, score cards, and decisions.
public protocol SessionStoring: Sendable {
    func saveSession(_ session: Session) async
    func session(withID id: UUID) async -> Session?
    func appendScoreCard(_ card: ScoreCard, sessionID: UUID) async
    func scoreCards(forFrame frameID: FrameID, sessionID: UUID) async -> [ScoreCard]
    func appendDecision(_ decision: CullDecision, sessionID: UUID) async
    func decisionLog(forSession sessionID: UUID) async -> DecisionLog
}

/// In-memory store for M0/M1. The GRDB/SQLite implementation lands when
/// durable sessions are needed (M2); `SessionStoring` is the seam, so callers
/// will not change. Append-only semantics are enforced HERE as well as in the
/// types: re-scores append new cards, never overwrite (invariant 6), and
/// decisions supersede, never mutate.
public actor InMemorySessionStore: SessionStoring {
    private var sessions: [UUID: Session] = [:]
    private var cards: [UUID: [ScoreCard]] = [:]
    private var decisions: [UUID: DecisionLog] = [:]

    public init() {}

    public func saveSession(_ session: Session) {
        sessions[session.id] = session
    }

    public func session(withID id: UUID) -> Session? {
        sessions[id]
    }

    public func appendScoreCard(_ card: ScoreCard, sessionID: UUID) {
        cards[sessionID, default: []].append(card)
    }

    public func scoreCards(forFrame frameID: FrameID, sessionID: UUID) -> [ScoreCard] {
        (cards[sessionID] ?? []).filter { $0.frameID == frameID }
    }

    public func appendDecision(_ decision: CullDecision, sessionID: UUID) {
        decisions[sessionID] = (decisions[sessionID] ?? DecisionLog()).appending(decision)
    }

    public func decisionLog(forSession sessionID: UUID) -> DecisionLog {
        decisions[sessionID] ?? DecisionLog()
    }
}
