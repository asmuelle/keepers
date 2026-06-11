import Foundation

/// Writes `.xmp` sidecars next to the RAWs — the ONLY writes Keepers ever
/// makes to a source volume (invariant 4). Originals are never modified,
/// moved, or deleted; re-exports overwrite only the sidecar itself.
public struct SidecarWriter: Sendable {
    public init() {}

    /// `IMG_0001.cr3` → `IMG_0001.xmp`, the naming Lightroom Classic pairs
    /// with the RAW on import.
    public func sidecarURL(forRawAt rawURL: URL) -> URL {
        rawURL.deletingPathExtension().appendingPathExtension("xmp")
    }

    @discardableResult
    public func write(_ sidecar: XMPSidecar, forRawAt rawURL: URL) throws -> URL {
        let destination = sidecarURL(forRawAt: rawURL)
        guard destination.pathExtension.lowercased() == "xmp",
              destination.standardizedFileURL != rawURL.standardizedFileURL
        else {
            throw ExportError.destinationIsNotSidecar(destination.lastPathComponent)
        }
        try Data(sidecar.serialized().utf8).write(to: destination, options: .atomic)
        return destination
    }
}
