import Foundation

/// An embedded JPEG preview extracted from a RAW — the ONLY pixel payload the
/// batch path ever touches (invariant 3: full RAW decode is loupe-on-demand).
public struct PreviewData: Sendable, Equatable {
    public let imageData: Data
    public let pixelWidth: Int
    public let pixelHeight: Int

    public init(imageData: Data, pixelWidth: Int, pixelHeight: Int) {
        self.imageData = imageData
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
    }
}

/// A frame paired with its extracted preview, ready for the scoring pipeline.
public struct ScorableFrame: Sendable, Equatable {
    public let frame: Frame
    public let preview: PreviewData

    public init(frame: Frame, preview: PreviewData) {
        self.frame = frame
        self.preview = preview
    }
}
