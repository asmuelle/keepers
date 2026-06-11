import Foundation
import KeepersCore
import PersistenceKit
import Testing

@Suite("In-memory session store")
struct SessionStoreTests {
    private let sessionID = UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!
    private let scoredAt = Date(timeIntervalSince1970: 1_750_000_000)

    private func card(_ frame: String, version: String) -> ScoreCard {
        ScoreCard(
            frameID: FrameID(frame),
            modelVersion: ModelVersion(rawValue: version),
            faceCount: 0,
            faces: [],
            aestheticsScore: nil,
            isUtility: false,
            sharpness: nil,
            featurePrint: nil,
            rankerScore: nil,
            compositeScore: 0.5,
            scoredAt: scoredAt
        )
    }

    @Test("sessions round-trip")
    func sessionRoundTrip() async {
        // Arrange
        let store = InMemorySessionStore()
        let session = Session(
            id: sessionID,
            name: "Wedding A",
            createdAt: scoredAt,
            frameCount: 3,
            status: .scoring,
            modelVersion: .VISION_ONLY_M1
        )

        // Act
        await store.saveSession(session)
        let loaded = await store.session(withID: sessionID)

        // Assert
        #expect(loaded == session)
    }

    @Test("re-scores append new cards and preserve prior versions (invariant 6)")
    func rescoreAppendsNeverOverwrites() async {
        // Arrange
        let store = InMemorySessionStore()

        // Act
        await store.appendScoreCard(card("a.cr3", version: "vision-only-1"), sessionID: sessionID)
        await store.appendScoreCard(card("a.cr3", version: "vision-only-2"), sessionID: sessionID)
        let cards = await store.scoreCards(forFrame: FrameID("a.cr3"), sessionID: sessionID)

        // Assert
        #expect(cards.count == 2)
        #expect(cards[0].modelVersion == ModelVersion(rawValue: "vision-only-1"))
        #expect(cards[1].modelVersion == ModelVersion(rawValue: "vision-only-2"))
    }

    @Test("decisions accumulate append-only per session")
    func decisionsAppendOnly() async throws {
        // Arrange
        let store = InMemorySessionStore()
        let pick = try CullDecision(
            frameID: FrameID("a.cr3"), verdict: .pick, starRating: 3, decidedBy: .user, decidedAt: scoredAt
        )
        let reject = try CullDecision(
            frameID: FrameID("a.cr3"), verdict: .reject, starRating: 1, decidedBy: .user, decidedAt: scoredAt
        )

        // Act
        await store.appendDecision(pick, sessionID: sessionID)
        await store.appendDecision(reject, sessionID: sessionID)
        let log = await store.decisionLog(forSession: sessionID)

        // Assert
        #expect(log.entries.count == 2)
        #expect(log.latestDecision(for: FrameID("a.cr3"))?.verdict == .reject)
    }
}
