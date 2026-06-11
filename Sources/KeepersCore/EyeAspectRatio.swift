/// Blink detection thresholds (eye-aspect-ratio per Soukupová & Čech 2016).
public enum BlinkDefaults {
    /// Below this eye-aspect-ratio an eye is considered closed.
    public static let EAR_THRESHOLD = 0.2
}

public enum EyeGeometryError: Error, Equatable {
    case degenerateEyeWidth
    case unsupportedPointCount(Int)
}

/// Six-point eye landmark layout for the EAR formula:
/// `EAR = (|p2−p6| + |p3−p5|) / (2·|p1−p4|)`.
/// p1/p4 are the horizontal corners, p2/p3 the upper lid, p6/p5 the lower lid.
public struct EyeLandmarks: Sendable, Equatable {
    public let p1: Point2D
    public let p2: Point2D
    public let p3: Point2D
    public let p4: Point2D
    public let p5: Point2D
    public let p6: Point2D

    public init(p1: Point2D, p2: Point2D, p3: Point2D, p4: Point2D, p5: Point2D, p6: Point2D) {
        self.p1 = p1
        self.p2 = p2
        self.p3 = p3
        self.p4 = p4
        self.p5 = p5
        self.p6 = p6
    }

    /// Adapter for eye-region contours as emitted by face-landmark detectors:
    /// corner-first winding over the top lid, then back under the bottom lid.
    /// Supports the 6-point and 8-point constellations.
    public init(eyeContour points: [Point2D]) throws {
        let count = points.count
        guard count == 6 || count == 8 else {
            throw EyeGeometryError.unsupportedPointCount(count)
        }
        self.init(
            p1: points[0],
            p2: points[1],
            p3: points[count / 2 - 1],
            p4: points[count / 2],
            p5: points[count / 2 + 1],
            p6: points[count - 1]
        )
    }

    public func eyeAspectRatio() throws -> Double {
        let width = p1.distance(to: p4)
        guard width > 0 else { throw EyeGeometryError.degenerateEyeWidth }
        return (p2.distance(to: p6) + p3.distance(to: p5)) / (2 * width)
    }

    public func isBlink(threshold: Double = BlinkDefaults.EAR_THRESHOLD) throws -> Bool {
        try eyeAspectRatio() < threshold
    }
}
