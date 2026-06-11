import Foundation

/// Stable identifier for a frame; in M1 this is the file name on the source volume.
public struct FrameID: Sendable, Hashable, Comparable, RawRepresentable, CustomStringConvertible {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }

    public static func < (lhs: FrameID, rhs: FrameID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var description: String {
        rawValue
    }
}

/// Camera file formats Keepers ingests (DESIGN.md data model).
public enum RawFileType: String, Sendable, CaseIterable {
    case cr3
    case nef
    case arw
    case raf
    case dng
    case jpeg

    public init?(fileExtension: String) {
        switch fileExtension.lowercased() {
        case "cr3": self = .cr3
        case "nef": self = .nef
        case "arw": self = .arw
        case "raf": self = .raf
        case "dng": self = .dng
        case "jpg", "jpeg": self = .jpeg
        default: return nil
        }
    }

    public var isRaw: Bool {
        self != .jpeg
    }
}

/// A frame on the source volume. Never the pixel data — invariant 3 (cull in place).
public struct Frame: Sendable, Hashable, Identifiable {
    public let id: FrameID
    public let relativePath: String
    public let fileType: RawFileType
    public let captureDate: Date?

    public init(id: FrameID, relativePath: String, fileType: RawFileType, captureDate: Date? = nil) {
        self.id = id
        self.relativePath = relativePath
        self.fileType = fileType
        self.captureDate = captureDate
    }
}
