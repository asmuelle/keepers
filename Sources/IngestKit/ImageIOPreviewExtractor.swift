#if canImport(ImageIO) && canImport(CoreGraphics) && canImport(UniformTypeIdentifiers)
    import CoreGraphics
    import Foundation
    import ImageIO
    import KeepersCore
    import UniformTypeIdentifiers

    /// Live extractor: pulls the embedded JPEG preview/thumbnail via CGImageSource.
    /// Not asserted in CI — preview bytes vary by OS and camera body; the pipeline
    /// is tested around it through `PreviewExtracting` (AGENTS.md testing policy).
    public struct ImageIOPreviewExtractor: PreviewExtracting {
        /// Working size cap for the batch path (DESIGN.md: previews ≤ 3MP-class).
        public static let MAX_PREVIEW_PIXEL_SIZE = 3072

        public init() {}

        public func extractEmbeddedPreview(from url: URL) throws -> PreviewData {
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
                throw PreviewExtractionError.unreadableSource(url.lastPathComponent)
            }
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
                kCGImageSourceThumbnailMaxPixelSize: Self.MAX_PREVIEW_PIXEL_SIZE
            ]
            guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
                throw PreviewExtractionError.noEmbeddedPreview(url.lastPathComponent)
            }
            return try PreviewData(
                imageData: jpegData(from: image, name: url.lastPathComponent),
                pixelWidth: image.width,
                pixelHeight: image.height
            )
        }

        private func jpegData(from image: CGImage, name: String) throws -> Data {
            let buffer = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(
                buffer,
                UTType.jpeg.identifier as CFString,
                1,
                nil
            ) else {
                throw PreviewExtractionError.noEmbeddedPreview(name)
            }
            CGImageDestinationAddImage(destination, image, nil)
            guard CGImageDestinationFinalize(destination) else {
                throw PreviewExtractionError.noEmbeddedPreview(name)
            }
            return buffer as Data
        }
    }
#endif
