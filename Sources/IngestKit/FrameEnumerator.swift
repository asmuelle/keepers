import Foundation
import KeepersCore

/// Seam over directory listing so enumeration logic is testable without
/// touching a real card.
public protocol DirectoryListing: Sendable {
    func fileURLs(inDirectory directory: URL) throws -> [URL]
}

public struct FileManagerDirectoryListing: DirectoryListing {
    public init() {}

    public func fileURLs(inDirectory directory: URL) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
    }
}

/// Enumerates supported camera files on the source volume. Read-only by
/// construction: it never copies, moves, or modifies anything (invariants 3+4).
public struct FrameEnumerator: Sendable {
    private let listing: any DirectoryListing

    public init(listing: any DirectoryListing = FileManagerDirectoryListing()) {
        self.listing = listing
    }

    /// Deterministic: results are sorted by file name. Hidden files and
    /// unsupported extensions are skipped.
    public func frames(inDirectory directory: URL) throws -> [Frame] {
        try listing.fileURLs(inDirectory: directory)
            .compactMap(makeFrame(from:))
            .sorted { $0.relativePath < $1.relativePath }
    }

    private func makeFrame(from url: URL) -> Frame? {
        let name = url.lastPathComponent
        guard !name.hasPrefix(".") else { return nil }
        guard let fileType = RawFileType(fileExtension: url.pathExtension) else { return nil }
        return Frame(id: FrameID(name), relativePath: name, fileType: fileType)
    }
}
