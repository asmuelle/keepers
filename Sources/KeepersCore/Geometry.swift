/// Minimal 2D point used by the eye-aspect-ratio blink math.
/// Plain value type so the math stays platform-free and exactly testable.
public struct Point2D: Sendable, Hashable {
    public let x: Double
    public let y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public func distance(to other: Point2D) -> Double {
        let dx = x - other.x
        let dy = y - other.y
        return (dx * dx + dy * dy).squareRoot()
    }
}
