public enum ExportError: Error, Equatable {
    case invalidStarRating(Int)
    case destinationIsNotSidecar(String)
}

/// Lightroom-readable color labels.
public enum XMPColorLabel: String, Sendable, CaseIterable {
    case red = "Red"
    case yellow = "Yellow"
    case green = "Green"
    case blue = "Blue"
    case purple = "Purple"
}

/// Minimal XMP packet carrying star rating + color label — exactly the fields
/// Lightroom Classic reads from sidecars. Pick/reject FLAGS are deliberately
/// absent: flags are Lightroom-catalog-only and do not survive XMP, and
/// Keepers never claims otherwise (invariant 8).
public struct XMPSidecar: Sendable, Equatable {
    public static let CREATOR_TOOL = "Keepers 0.1.0"

    public let rating: Int
    public let label: XMPColorLabel?

    public init(rating: Int, label: XMPColorLabel? = nil) throws {
        guard (0 ... 5).contains(rating) else {
            throw ExportError.invalidStarRating(rating)
        }
        self.rating = rating
        self.label = label
    }

    /// Deterministic, byte-stable serialization — golden-file tested. The
    /// label enum is the only dynamic text and every raw value is XML-safe,
    /// so no escaping pass is needed.
    public func serialized() -> String {
        var lines = [
            "<?xpacket begin=\"\u{FEFF}\" id=\"W5M0MpCehiHzreSzNTczkc9d\"?>",
            "<x:xmpmeta xmlns:x=\"adobe:ns:meta/\" x:xmptk=\"\(Self.CREATOR_TOOL)\">",
            " <rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">",
            "  <rdf:Description rdf:about=\"\"",
            "      xmlns:xmp=\"http://ns.adobe.com/xap/1.0/\""
        ]
        if let label {
            lines.append("      xmp:Rating=\"\(rating)\"")
            lines.append("      xmp:Label=\"\(label.rawValue)\"/>")
        } else {
            lines.append("      xmp:Rating=\"\(rating)\"/>")
        }
        lines.append(contentsOf: [
            " </rdf:RDF>",
            "</x:xmpmeta>",
            "<?xpacket end=\"w\"?>",
            ""
        ])
        return lines.joined(separator: "\n")
    }
}
