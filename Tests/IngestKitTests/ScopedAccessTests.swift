import IngestKit
import Synchronization
import Testing

/// Counts start/stop calls so the pairing discipline is observable.
private final class MockScopedResource: SecurityScopedResource {
    struct Counts: Equatable {
        var starts = 0
        var stops = 0
    }

    private let counts = Mutex(Counts())
    private let allowsAccess: Bool

    init(allowsAccess: Bool) {
        self.allowsAccess = allowsAccess
    }

    func startAccessing() -> Bool {
        guard allowsAccess else { return false }
        counts.withLock { $0.starts += 1 }
        return true
    }

    func stopAccessing() {
        counts.withLock { $0.stops += 1 }
    }

    var snapshot: Counts {
        counts.withLock { $0 }
    }
}

private struct BodyError: Error {}

@Suite("Security-scoped access pairing (invariant 5)")
struct ScopedAccessTests {
    @Test("successful body: exactly one start and one stop")
    func pairedStartStop() throws {
        // Arrange
        let resource = MockScopedResource(allowsAccess: true)

        // Act
        let value = try ScopedAccess.withAccess(to: resource) { 42 }

        // Assert
        #expect(value == 42)
        #expect(resource.snapshot == .init(starts: 1, stops: 1))
    }

    @Test("throwing body still releases access exactly once")
    func stopOnThrow() {
        // Arrange
        let resource = MockScopedResource(allowsAccess: true)

        // Act
        #expect(throws: BodyError.self) {
            try ScopedAccess.withAccess(to: resource) { throw BodyError() }
        }

        // Assert
        #expect(resource.snapshot == .init(starts: 1, stops: 1))
    }

    @Test("denied access throws a typed error and never calls stop")
    func deniedAccessNeverStops() {
        // Arrange
        let resource = MockScopedResource(allowsAccess: false)

        // Act
        #expect(throws: ScopedAccessError.accessDenied) {
            try ScopedAccess.withAccess(to: resource) { 0 }
        }

        // Assert
        #expect(resource.snapshot == .init(starts: 0, stops: 0))
    }

    @Test("nested access on the same resource stays balanced")
    func nestedAccessBalanced() throws {
        // Arrange
        let resource = MockScopedResource(allowsAccess: true)

        // Act
        try ScopedAccess.withAccess(to: resource) {
            try ScopedAccess.withAccess(to: resource) { () }
        }

        // Assert
        #expect(resource.snapshot == .init(starts: 2, stops: 2))
    }
}
