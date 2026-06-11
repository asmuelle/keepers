import Foundation

/// Abstraction over security-scoped resource access so the pairing discipline
/// is testable without a real external volume.
public protocol SecurityScopedResource: Sendable {
    func startAccessing() -> Bool
    func stopAccessing()
}

public enum ScopedAccessError: Error, Equatable {
    case accessDenied
}

public enum ScopedAccess {
    /// Invariant 5: every successful start is paired with EXACTLY one stop,
    /// even when the body throws. This helper is the only sanctioned way to
    /// touch a scoped resource — never call the raw start/stop API at call sites.
    public static func withAccess<T>(
        to resource: some SecurityScopedResource,
        perform body: () throws -> T
    ) throws -> T {
        guard resource.startAccessing() else {
            throw ScopedAccessError.accessDenied
        }
        defer { resource.stopAccessing() }
        return try body()
    }
}

extension URL: SecurityScopedResource {
    public func startAccessing() -> Bool {
        startAccessingSecurityScopedResource()
    }

    public func stopAccessing() {
        stopAccessingSecurityScopedResource()
    }
}
