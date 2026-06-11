import KeepersCore
import Testing

@Suite("Near-duplicate clustering")
struct DupeClusteringTests {
    @Test("near-identical prints cluster together; distinct prints stay apart")
    func clustersNearDuplicates() {
        // Arrange
        let frames = [
            FramePrint(id: FrameID("a1"), print: FeaturePrintVector([1.0, 0.0])),
            FramePrint(id: FrameID("a2"), print: FeaturePrintVector([0.999, 0.01])),
            FramePrint(id: FrameID("b"), print: FeaturePrintVector([0.0, 1.0]))
        ]

        // Act
        let clusters = DupeClusterer.clusters(of: frames)

        // Assert
        #expect(clusters.count == 2)
        #expect(clusters[0].memberIDs == [FrameID("a1"), FrameID("a2")])
        #expect(clusters[0].representativeID == FrameID("a1"))
        #expect(clusters[1].memberIDs == [FrameID("b")])
    }

    @Test("frames without a print are singletons and never absorb others")
    func nilPrintsAreSingletons() {
        let frames = [
            FramePrint(id: FrameID("x"), print: nil),
            FramePrint(id: FrameID("y"), print: nil)
        ]
        let clusters = DupeClusterer.clusters(of: frames)
        #expect(clusters.count == 2)
    }

    @Test("distance exactly at the threshold joins the cluster (≤ semantics)")
    func thresholdBoundaryJoins() {
        // Arrange: orthogonal vectors have distance exactly 1.0
        let frames = [
            FramePrint(id: FrameID("p"), print: FeaturePrintVector([1, 0])),
            FramePrint(id: FrameID("q"), print: FeaturePrintVector([0, 1]))
        ]

        // Act
        let joined = DupeClusterer.clusters(of: frames, distanceThreshold: 1.0)
        let split = DupeClusterer.clusters(of: frames, distanceThreshold: 0.999)

        // Assert
        #expect(joined.count == 1)
        #expect(split.count == 2)
    }

    @Test("clustering is deterministic for a given input order")
    func deterministicForInputOrder() {
        let frames = [
            FramePrint(id: FrameID("1"), print: FeaturePrintVector([1, 0, 0])),
            FramePrint(id: FrameID("2"), print: FeaturePrintVector([0.99, 0.05, 0])),
            FramePrint(id: FrameID("3"), print: FeaturePrintVector([0, 0, 1]))
        ]
        #expect(DupeClusterer.clusters(of: frames) == DupeClusterer.clusters(of: frames))
    }
}
