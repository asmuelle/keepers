import KeepersCore
import RankerKit
import Testing

@Suite("RankerKit boundary (M1 placeholder)")
struct RankerKitTests {
    @Test("NoOpRanker returns nil — M1 composites are Vision-only by design")
    func noOpRankerReturnsNil() {
        let analysis = FrameAnalysis(
            frameID: FrameID("IMG_0001.cr3"),
            faces: [],
            aestheticsScore: 0.4,
            isUtility: false,
            featurePrint: nil
        )
        #expect(NoOpRanker().rankerScore(for: analysis) == nil)
    }
}
