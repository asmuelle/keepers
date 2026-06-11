import Foundation
import IngestKit
import Testing

private let STALE_DATA = Data("stale".utf8)
private let FRESH_DATA = Data("fresh".utf8)
private let CARD_URL = URL(fileURLWithPath: "/Volumes/CARD")

/// Resolver where only `STALE_DATA` resolves stale; minting always yields fresh data.
private struct RecoveringResolver: BookmarkResolving {
    func resolve(_ bookmarkData: Data) throws -> ResolvedBookmark {
        ResolvedBookmark(url: CARD_URL, wasStale: bookmarkData == STALE_DATA)
    }

    func makeBookmarkData(for _: URL) throws -> Data {
        FRESH_DATA
    }
}

/// Resolver whose bookmarks are stale no matter how often they are re-minted.
private struct AlwaysStaleResolver: BookmarkResolving {
    func resolve(_: Data) throws -> ResolvedBookmark {
        ResolvedBookmark(url: CARD_URL, wasStale: true)
    }

    func makeBookmarkData(for _: URL) throws -> Data {
        STALE_DATA
    }
}

private struct UnresolvableResolver: BookmarkResolving {
    func resolve(_: Data) throws -> ResolvedBookmark {
        throw BookmarkError.unresolvable
    }

    func makeBookmarkData(for _: URL) throws -> Data {
        throw BookmarkError.unresolvable
    }
}

@Suite("Bookmark stale-resolution (invariant 5)")
struct BookmarkResolutionTests {
    @Test("a fresh bookmark passes straight through")
    func freshBookmarkPassesThrough() throws {
        let resolved = try BookmarkRefresher.resolveFresh(FRESH_DATA, using: RecoveringResolver())
        #expect(resolved == ResolvedBookmark(url: CARD_URL, wasStale: false))
    }

    @Test("a stale bookmark is re-minted from the resolved URL and recovered")
    func staleBookmarkRecovers() throws {
        let resolved = try BookmarkRefresher.resolveFresh(STALE_DATA, using: RecoveringResolver())
        #expect(resolved.wasStale == false)
        #expect(resolved.url == CARD_URL)
    }

    @Test("persistently stale bookmarks surface a typed error, never a crash")
    func unrecoverableStaleThrows() {
        #expect(throws: BookmarkError.staleAndUnrecoverable) {
            try BookmarkRefresher.resolveFresh(STALE_DATA, using: AlwaysStaleResolver())
        }
    }

    @Test("unresolvable bookmarks propagate the typed error")
    func unresolvableThrows() {
        #expect(throws: BookmarkError.unresolvable) {
            try BookmarkRefresher.resolveFresh(FRESH_DATA, using: UnresolvableResolver())
        }
    }
}
