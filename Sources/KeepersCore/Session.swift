import Foundation

public enum SessionStatus: String, Sendable, CaseIterable {
    case ingesting
    case scoring
    case reviewed
    case exported
}

/// A culling session (DESIGN.md data model). Immutable — state changes
/// produce a new value via `with(status:)`.
public struct Session: Sendable, Hashable, Identifiable {
    public let id: UUID
    public let name: String
    public let createdAt: Date
    public let frameCount: Int
    public let status: SessionStatus
    public let modelVersion: ModelVersion

    public init(
        id: UUID,
        name: String,
        createdAt: Date,
        frameCount: Int,
        status: SessionStatus,
        modelVersion: ModelVersion
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.frameCount = frameCount
        self.status = status
        self.modelVersion = modelVersion
    }

    public func with(status newStatus: SessionStatus) -> Session {
        Session(
            id: id,
            name: name,
            createdAt: createdAt,
            frameCount: frameCount,
            status: newStatus,
            modelVersion: modelVersion
        )
    }
}
