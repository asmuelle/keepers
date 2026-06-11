#if canImport(Vision)
    import Foundation
    import KeepersCore
    import Vision

    /// Live Vision-backed analyzer running the four platform requests on the
    /// embedded preview. Compiles wherever Vision exists; requires iOS 18 /
    /// macOS 15 for the modern request API. Never asserted in CI — Vision outputs
    /// vary across OS versions (AGENTS.md testing policy); CI exercises the
    /// pipeline through `FrameAnalyzing` with the deterministic mock instead.
    @available(iOS 18.0, macOS 15.0, *)
    public struct VisionFrameAnalyzer: FrameAnalyzing {
        public init() {}

        public func analyze(frame: Frame, preview: PreviewData) async throws -> FrameAnalysis {
            let data = preview.imageData
            let landmarkFaces = try await DetectFaceLandmarksRequest().perform(on: data)
            let qualityFaces = try await DetectFaceCaptureQualityRequest().perform(on: data)
            let aesthetics = try await CalculateImageAestheticsScoresRequest().perform(on: data)
            let featurePrint = try await GenerateImageFeaturePrintRequest().perform(on: data)
            return FrameAnalysis(
                frameID: frame.id,
                faces: Self.faces(landmarks: landmarkFaces, quality: qualityFaces),
                aestheticsScore: Double(aesthetics.overallScore),
                isUtility: aesthetics.isUtility,
                featurePrint: Self.vector(from: featurePrint)
            )
        }

        /// Pairs landmark faces with capture-quality faces by detection index
        /// (same image, same detector ordering). Quality scores are only ever
        /// compared within one burst of the same subject — platform contract.
        private static func faces(
            landmarks: [FaceObservation],
            quality: [FaceObservation]
        ) -> [FaceAnalysis] {
            landmarks.enumerated().map { index, face in
                let qualityScore: Double? = index < quality.count
                    ? quality[index].captureQuality.map { Double($0.score) }
                    : nil
                return FaceAnalysis(
                    captureQuality: qualityScore,
                    leftEyeAspectRatio: eyeAspectRatio(of: face.landmarks?.leftEye),
                    rightEyeAspectRatio: eyeAspectRatio(of: face.landmarks?.rightEye)
                )
            }
        }

        /// EAR on normalized landmark coordinates. Aspect-ratio distortion from
        /// normalization is acceptable for the v1 blink gate; the loupe shows the
        /// raw value so the photographer can judge.
        private static func eyeAspectRatio(of region: FaceObservation.Landmarks2D.Region?) -> Double? {
            guard let region else { return nil }
            let points = region.points.map { Point2D(x: Double($0.x), y: Double($0.y)) }
            guard let eye = try? EyeLandmarks(eyeContour: points) else { return nil }
            return try? eye.eyeAspectRatio()
        }

        private static func vector(from observation: FeaturePrintObservation) -> FeaturePrintVector? {
            guard observation.elementType == .float else { return nil }
            let floats = observation.data.withUnsafeBytes { buffer in
                Array(buffer.bindMemory(to: Float.self))
            }
            return FeaturePrintVector(floats.map(Double.init))
        }
    }
#endif
