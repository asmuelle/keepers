import KeepersCore

/// The seam between the deterministic pipeline and platform AI. Everything on
/// the other side of this protocol (Vision, future Core ML ranker inputs) is
/// non-portable across OS versions, so CI tests the pipeline AROUND it with
/// the deterministic mock; real-model assertions live in device smoke tests.
public protocol FrameAnalyzing: Sendable {
    func analyze(frame: Frame, preview: PreviewData) async throws -> FrameAnalysis
}
