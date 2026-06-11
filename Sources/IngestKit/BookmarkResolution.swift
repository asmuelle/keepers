import Foundation

public struct ResolvedBookmark: Sendable, Equatable {
    public let url: URL
    public let wasStale: Bool

    public init(url: URL, wasStale: Bool) {
        self.url = url
        self.wasStale = wasStale
    }
}

public enum BookmarkError: Error, Equatable {
    case unresolvable
    case staleAndUnrecoverable
}

/// Seam over Foundation's bookmark APIs so the stale-recovery flow is testable.
public protocol BookmarkResolving: Sendable {
    func resolve(_ bookmarkData: Data) throws -> ResolvedBookmark
    func makeBookmarkData(for url: URL) throws -> Data
}

public enum BookmarkRefresher {
    /// Resolves a bookmark; on staleness it mints a fresh bookmark from the
    /// resolved URL and re-resolves. Staleness NEVER crashes (invariant 5) —
    /// unrecoverable cases surface as typed errors the UI can act on.
    public static func resolveFresh(
        _ bookmarkData: Data,
        using resolver: some BookmarkResolving
    ) throws -> ResolvedBookmark {
        let first = try resolver.resolve(bookmarkData)
        guard first.wasStale else { return first }

        let refreshedData = try resolver.makeBookmarkData(for: first.url)
        let second = try resolver.resolve(refreshedData)
        guard !second.wasStale else {
            throw BookmarkError.staleAndUnrecoverable
        }
        return second
    }
}

/// Live implementation backed by Foundation. Exercised on device, not in CI
/// (bookmark behavior depends on real volumes); CI covers the recovery flow
/// through the protocol seam.
public struct FoundationBookmarkResolver: BookmarkResolving {
    public init() {}

    public func resolve(_ bookmarkData: Data) throws -> ResolvedBookmark {
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            throw BookmarkError.unresolvable
        }
        return ResolvedBookmark(url: url, wasStale: isStale)
    }

    public func makeBookmarkData(for url: URL) throws -> Data {
        do {
            return try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
        } catch {
            throw BookmarkError.unresolvable
        }
    }
}
