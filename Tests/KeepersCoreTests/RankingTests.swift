import Foundation
import KeepersCore
import Testing

@Suite("Ranking")
struct RankingTests {
    private let scoredAt = Date(timeIntervalSince1970: 1_750_000_000)

    private func card(_ id: String, composite: Double) -> ScoreCard {
        ScoreCard(
            frameID: FrameID(id),
            modelVersion: .VISION_ONLY_M1,
            faceCount: 0,
            faces: [],
            aestheticsScore: nil,
            isUtility: false,
            sharpness: nil,
            featurePrint: nil,
            rankerScore: nil,
            compositeScore: composite,
            scoredAt: scoredAt
        )
    }

    @Test("orders by composite descending")
    func ordersByCompositeDescending() {
        let ranked = Ranking.rankedFrameIDs(of: [
            card("low", composite: 0.2),
            card("high", composite: 0.9),
            card("mid", composite: 0.5)
        ])
        #expect(ranked == [FrameID("high"), FrameID("mid"), FrameID("low")])
    }

    @Test("equal composites tie-break by ascending frame id")
    func tieBreaksByFrameID() {
        let ranked = Ranking.rankedFrameIDs(of: [
            card("b", composite: 0.5),
            card("a", composite: 0.5)
        ])
        #expect(ranked == [FrameID("a"), FrameID("b")])
    }

    @Test("ranking is independent of input order (invariant 6)")
    func deterministicAcrossInputOrders() {
        let cards = [
            card("x", composite: 0.31),
            card("y", composite: 0.77),
            card("z", composite: 0.31)
        ]
        #expect(Ranking.rankedFrameIDs(of: cards) == Ranking.rankedFrameIDs(of: cards.reversed()))
    }
}
