import KeepersCore

/// Verdict → XMP mapping (DESIGN flow 3 defaults): picks → ★★★,
/// rejects → red label + ★, maybe → unrated. Configurable per export job.
public struct ExportMapping: Sendable, Equatable {
    public let pickRating: Int
    public let rejectRating: Int
    public let rejectLabel: XMPColorLabel?
    public let maybeRating: Int

    public static let DEFAULT = ExportMapping(
        pickRating: 3,
        rejectRating: 1,
        rejectLabel: .red,
        maybeRating: 0
    )

    public init(pickRating: Int, rejectRating: Int, rejectLabel: XMPColorLabel?, maybeRating: Int) {
        self.pickRating = pickRating
        self.rejectRating = rejectRating
        self.rejectLabel = rejectLabel
        self.maybeRating = maybeRating
    }

    public func sidecar(for verdict: Verdict) throws -> XMPSidecar {
        switch verdict {
        case .pick: try XMPSidecar(rating: pickRating)
        case .reject: try XMPSidecar(rating: rejectRating, label: rejectLabel)
        case .maybe: try XMPSidecar(rating: maybeRating)
        }
    }
}
