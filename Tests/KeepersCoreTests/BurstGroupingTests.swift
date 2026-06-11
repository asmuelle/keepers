import Foundation
import KeepersCore
import Testing

@Suite("Burst grouping")
struct BurstGroupingTests {
    private let epoch = Date(timeIntervalSince1970: 1_750_000_000)
    private let similarPrint = FeaturePrintVector([1, 0.1])

    private func candidate(
        _ id: String,
        offset: TimeInterval,
        print: FeaturePrintVector?,
        bestness: Double = 0.5
    ) -> BurstCandidate {
        BurstCandidate(
            id: FrameID(id),
            captureDate: epoch.addingTimeInterval(offset),
            print: print,
            bestnessScore: bestness
        )
    }

    @Test("time-adjacent, similar frames form one burst with the best on top")
    func groupsAdjacentFrames() {
        // Arrange: three frames 0.4s apart, same print direction
        let candidates = [
            candidate("a", offset: 0.0, print: similarPrint, bestness: 0.4),
            candidate("b", offset: 0.4, print: similarPrint, bestness: 0.9),
            candidate("c", offset: 0.8, print: similarPrint, bestness: 0.6)
        ]

        // Act
        let bursts = BurstGrouper.bursts(in: candidates)

        // Assert
        #expect(bursts.count == 1)
        #expect(bursts[0].memberIDs == [FrameID("a"), FrameID("b"), FrameID("c")])
        #expect(bursts[0].suggestedBestID == FrameID("b"))
    }

    @Test("a capture gap beyond the limit splits the run")
    func timeGapSplits() {
        let candidates = [
            candidate("a", offset: 0.0, print: similarPrint),
            candidate("b", offset: 0.5, print: similarPrint),
            candidate("c", offset: 5.0, print: similarPrint),
            candidate("d", offset: 5.4, print: similarPrint)
        ]
        let bursts = BurstGrouper.bursts(in: candidates)
        #expect(bursts.count == 2)
        #expect(bursts[0].memberIDs == [FrameID("a"), FrameID("b")])
        #expect(bursts[1].memberIDs == [FrameID("c"), FrameID("d")])
    }

    @Test("dissimilar feature prints split despite time adjacency")
    func printDistanceSplits() {
        let candidates = [
            candidate("a", offset: 0.0, print: FeaturePrintVector([1, 0])),
            candidate("b", offset: 0.3, print: FeaturePrintVector([0, 1]))
        ]
        let bursts = BurstGrouper.bursts(in: candidates)
        #expect(bursts.isEmpty) // two singletons, no burst
    }

    @Test("singletons are not bursts")
    func singletonsExcluded() {
        let bursts = BurstGrouper.bursts(in: [candidate("only", offset: 0, print: similarPrint)])
        #expect(bursts.isEmpty)
    }

    @Test("bestness tie breaks to the lowest frame id")
    func bestnessTieBreaksDeterministically() {
        let candidates = [
            candidate("b", offset: 0.0, print: similarPrint, bestness: 0.7),
            candidate("a", offset: 0.4, print: similarPrint, bestness: 0.7)
        ]
        let bursts = BurstGrouper.bursts(in: candidates)
        #expect(bursts.count == 1)
        #expect(bursts[0].suggestedBestID == FrameID("a"))
    }

    @Test("input order does not matter — grouping sorts by capture time")
    func unsortedInputIsSorted() {
        let candidates = [
            candidate("late", offset: 0.8, print: similarPrint),
            candidate("early", offset: 0.0, print: similarPrint),
            candidate("mid", offset: 0.4, print: similarPrint)
        ]
        let bursts = BurstGrouper.bursts(in: candidates)
        #expect(bursts.count == 1)
        #expect(bursts[0].memberIDs == [FrameID("early"), FrameID("mid"), FrameID("late")])
    }
}
