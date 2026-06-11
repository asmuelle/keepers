/// An image feature print as a plain vector, decoupled from any OS observation
/// type so the clustering math is pure and testable.
public struct FeaturePrintVector: Sendable, Equatable {
    public let values: [Double]

    public init(_ values: [Double]) {
        self.values = values
    }
}

public enum VectorMathError: Error, Equatable {
    case emptyVector
    case dimensionMismatch(lhs: Int, rhs: Int)
    case zeroMagnitude
}

public enum VectorMath {
    /// Cosine similarity in [−1, 1]. Throws instead of silently producing NaN.
    public static func cosineSimilarity(_ a: FeaturePrintVector, _ b: FeaturePrintVector) throws -> Double {
        guard !a.values.isEmpty, !b.values.isEmpty else {
            throw VectorMathError.emptyVector
        }
        guard a.values.count == b.values.count else {
            throw VectorMathError.dimensionMismatch(lhs: a.values.count, rhs: b.values.count)
        }
        var dot = 0.0
        var magnitudeA = 0.0
        var magnitudeB = 0.0
        for index in a.values.indices {
            let lhs = a.values[index]
            let rhs = b.values[index]
            dot += lhs * rhs
            magnitudeA += lhs * lhs
            magnitudeB += rhs * rhs
        }
        guard magnitudeA > 0, magnitudeB > 0 else {
            throw VectorMathError.zeroMagnitude
        }
        return dot / (magnitudeA.squareRoot() * magnitudeB.squareRoot())
    }

    /// Cosine distance in [0, 2]: 0 = identical direction, 1 = orthogonal.
    public static func cosineDistance(_ a: FeaturePrintVector, _ b: FeaturePrintVector) throws -> Double {
        try 1 - cosineSimilarity(a, b)
    }
}
