import Foundation
import KeepersCore
import Testing

@Suite("Cull decisions — append-only, supersede never mutate")
struct DecisionLogTests {
    private let decidedAt = Date(timeIntervalSince1970: 1_750_000_000)

    private func decision(_ id: String, _ verdict: Verdict, stars: Int = 3) throws -> CullDecision {
        try CullDecision(
            frameID: FrameID(id),
            verdict: verdict,
            starRating: stars,
            decidedBy: .user,
            decidedAt: decidedAt
        )
    }

    @Test("appending returns a new log and leaves the original untouched")
    func appendingIsImmutable() throws {
        // Arrange
        let original = DecisionLog()

        // Act
        let appended = try original.appending(decision("a.cr3", .pick))

        // Assert
        #expect(original.entries.isEmpty)
        #expect(appended.entries.count == 1)
    }

    @Test("a newer decision supersedes but the old one is preserved as training signal")
    func supersedePreservesHistory() throws {
        // Arrange
        let log = try DecisionLog()
            .appending(decision("a.cr3", .pick))
            .appending(decision("a.cr3", .reject, stars: 1))

        // Act
        let latest = log.latestDecision(for: FrameID("a.cr3"))

        // Assert
        #expect(latest?.verdict == .reject)
        #expect(log.entries.count == 2)
        #expect(log.entries[0].verdict == .pick)
    }

    @Test("latestDecisions maps each frame to its newest decision")
    func latestDecisionsMap() throws {
        let log = try DecisionLog()
            .appending(decision("a.cr3", .pick))
            .appending(decision("b.cr3", .maybe))
            .appending(decision("a.cr3", .reject, stars: 1))

        let latest = log.latestDecisions()
        #expect(latest.count == 2)
        #expect(latest[FrameID("a.cr3")]?.verdict == .reject)
        #expect(latest[FrameID("b.cr3")]?.verdict == .maybe)
    }

    @Test("star ratings outside 0...5 throw")
    func invalidStarRatingThrows() {
        #expect(throws: DecisionError.invalidStarRating(6)) {
            try CullDecision(
                frameID: FrameID("a.cr3"),
                verdict: .pick,
                starRating: 6,
                decidedBy: .user,
                decidedAt: decidedAt
            )
        }
    }
}
