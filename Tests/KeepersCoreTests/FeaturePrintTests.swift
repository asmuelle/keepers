import KeepersCore
import Testing

@Suite("Feature-print cosine math")
struct FeaturePrintTests {
    @Test("parallel vectors have similarity 1")
    func parallelVectors() throws {
        let similarity = try VectorMath.cosineSimilarity(
            FeaturePrintVector([1, 2]),
            FeaturePrintVector([2, 4])
        )
        #expect(abs(similarity - 1) < 1e-12)
    }

    @Test("orthogonal vectors have similarity 0")
    func orthogonalVectors() throws {
        let similarity = try VectorMath.cosineSimilarity(
            FeaturePrintVector([1, 0]),
            FeaturePrintVector([0, 1])
        )
        #expect(similarity == 0)
    }

    @Test("opposite vectors have similarity −1")
    func oppositeVectors() throws {
        let similarity = try VectorMath.cosineSimilarity(
            FeaturePrintVector([1, 0]),
            FeaturePrintVector([-1, 0])
        )
        #expect(similarity == -1)
    }

    @Test("cosine distance is 1 − similarity")
    func distanceComplementsSimilarity() throws {
        let distance = try VectorMath.cosineDistance(
            FeaturePrintVector([1, 0]),
            FeaturePrintVector([0, 1])
        )
        #expect(distance == 1)
    }

    @Test("empty vectors throw")
    func emptyVectorThrows() {
        #expect(throws: VectorMathError.emptyVector) {
            try VectorMath.cosineSimilarity(FeaturePrintVector([]), FeaturePrintVector([1]))
        }
    }

    @Test("dimension mismatch throws")
    func dimensionMismatchThrows() {
        #expect(throws: VectorMathError.dimensionMismatch(lhs: 2, rhs: 3)) {
            try VectorMath.cosineSimilarity(FeaturePrintVector([1, 2]), FeaturePrintVector([1, 2, 3]))
        }
    }

    @Test("zero-magnitude vectors throw instead of producing NaN")
    func zeroMagnitudeThrows() {
        #expect(throws: VectorMathError.zeroMagnitude) {
            try VectorMath.cosineSimilarity(FeaturePrintVector([0, 0]), FeaturePrintVector([1, 1]))
        }
    }
}
