import Foundation
import KeepersCore

public enum PreviewExtractionError: Error, Equatable {
    case unreadableSource(String)
    case noEmbeddedPreview(String)
}

/// Extracts the EMBEDDED JPEG preview from a camera file — never a full RAW
/// decode (invariant 3: full decode is loupe-on-demand only).
public protocol PreviewExtracting: Sendable {
    func extractEmbeddedPreview(from url: URL) throws -> PreviewData
}

/// Deterministic stand-in used by tests and the demo session: derives a tiny
/// stable payload from the file name (FNV-1a), so the whole pipeline runs
/// hermetically with zero image assets.
public struct MockPreviewExtractor: PreviewExtracting {
    public static let MOCK_PIXEL_WIDTH = 3072
    public static let MOCK_PIXEL_HEIGHT = 2048

    public init() {}

    public func extractEmbeddedPreview(from url: URL) throws -> PreviewData {
        let hash = StableHash.fnv1a(url.lastPathComponent)
        let payload = withUnsafeBytes(of: hash.bigEndian) { Data($0) }
        return PreviewData(
            imageData: payload,
            pixelWidth: Self.MOCK_PIXEL_WIDTH,
            pixelHeight: Self.MOCK_PIXEL_HEIGHT
        )
    }
}
