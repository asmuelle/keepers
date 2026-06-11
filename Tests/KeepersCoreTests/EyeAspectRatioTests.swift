import KeepersCore
import Testing

@Suite("Eye-aspect-ratio blink math")
struct EyeAspectRatioTests {
    /// Builds an eye with width 4 whose EAR is exactly `target`.
    private func eye(withEAR target: Double) -> EyeLandmarks {
        EyeLandmarks(
            p1: Point2D(x: 0, y: 0),
            p2: Point2D(x: 1, y: 2 * target),
            p3: Point2D(x: 3, y: 2 * target),
            p4: Point2D(x: 4, y: 0),
            p5: Point2D(x: 3, y: -2 * target),
            p6: Point2D(x: 1, y: -2 * target)
        )
    }

    @Test("open eye yields the golden EAR value 0.3")
    func openEyeGoldenValue() throws {
        // Arrange
        let landmarks = EyeLandmarks(
            p1: Point2D(x: 0, y: 0),
            p2: Point2D(x: 1, y: 0.6),
            p3: Point2D(x: 3, y: 0.6),
            p4: Point2D(x: 4, y: 0),
            p5: Point2D(x: 3, y: -0.6),
            p6: Point2D(x: 1, y: -0.6)
        )

        // Act
        let ear = try landmarks.eyeAspectRatio()

        // Assert: (1.2 + 1.2) / (2 * 4) = 0.3
        #expect(abs(ear - 0.3) < 1e-9)
    }

    @Test("closed eye yields a low EAR")
    func closedEyeGoldenValue() throws {
        // Arrange
        let landmarks = eye(withEAR: 0.025)

        // Act
        let ear = try landmarks.eyeAspectRatio()

        // Assert
        #expect(abs(ear - 0.025) < 1e-9)
        #expect(try landmarks.isBlink())
    }

    @Test("zero-width eye throws instead of dividing by zero")
    func degenerateEyeThrows() {
        // Arrange
        let point = Point2D(x: 1, y: 1)
        let landmarks = EyeLandmarks(p1: point, p2: point, p3: point, p4: point, p5: point, p6: point)

        // Act / Assert
        #expect(throws: EyeGeometryError.degenerateEyeWidth) {
            try landmarks.eyeAspectRatio()
        }
    }

    @Test("EAR just below threshold classifies as blink")
    func blinkJustBelowThreshold() throws {
        #expect(try eye(withEAR: 0.19).isBlink())
    }

    @Test("EAR just above threshold classifies as open")
    func openJustAboveThreshold() throws {
        #expect(try !eye(withEAR: 0.21).isBlink())
    }

    @Test("6-point eye contour maps to the same EAR as direct construction")
    func sixPointContourAdapter() throws {
        // Arrange: contour winding — corner, top lid, corner, bottom lid
        let contour = [
            Point2D(x: 0, y: 0),
            Point2D(x: 1, y: 0.6),
            Point2D(x: 3, y: 0.6),
            Point2D(x: 4, y: 0),
            Point2D(x: 3, y: -0.6),
            Point2D(x: 1, y: -0.6)
        ]

        // Act
        let ear = try EyeLandmarks(eyeContour: contour).eyeAspectRatio()

        // Assert
        #expect(abs(ear - 0.3) < 1e-9)
    }

    @Test("8-point eye contour is supported")
    func eightPointContourAdapter() throws {
        // Arrange: corners at 0 and 4, lids above/below
        let contour = [
            Point2D(x: 0, y: 0),
            Point2D(x: 1, y: 0.5),
            Point2D(x: 2, y: 0.6),
            Point2D(x: 3, y: 0.5),
            Point2D(x: 4, y: 0),
            Point2D(x: 3, y: -0.5),
            Point2D(x: 2, y: -0.6),
            Point2D(x: 1, y: -0.5)
        ]

        // Act
        let landmarks = try EyeLandmarks(eyeContour: contour)
        let ear = try landmarks.eyeAspectRatio()

        // Assert: p2=(1,0.5)/p6=(1,-0.5) → 1.0; p3=(3,0.5)/p5=(3,-0.5) → 1.0; width 4
        #expect(abs(ear - 0.25) < 1e-9)
    }

    @Test("unsupported contour point counts throw")
    func unsupportedContourThrows() {
        let contour = Array(repeating: Point2D(x: 0, y: 0), count: 5)
        #expect(throws: EyeGeometryError.unsupportedPointCount(5)) {
            try EyeLandmarks(eyeContour: contour)
        }
    }
}

@Suite("FaceAnalysis blink classification")
struct FaceAnalysisBlinkTests {
    @Test("lowest available EAR below threshold means blinking")
    func oneClosedEyeIsBlink() {
        let face = FaceAnalysis(captureQuality: 0.9, leftEyeAspectRatio: 0.11, rightEyeAspectRatio: 0.3)
        #expect(face.isBlinking())
    }

    @Test("both eyes open means not blinking")
    func openEyesNotBlink() {
        let face = FaceAnalysis(captureQuality: 0.9, leftEyeAspectRatio: 0.3, rightEyeAspectRatio: 0.28)
        #expect(!face.isBlinking())
    }

    @Test("missing eye landmarks never count as a blink")
    func unknownEyesNotBlink() {
        let face = FaceAnalysis(captureQuality: 0.9, leftEyeAspectRatio: nil, rightEyeAspectRatio: nil)
        #expect(!face.isBlinking())
    }
}
