import Foundation
import Testing

/// Source-level enforcement of the two architectural invariants:
/// 1 — no image egress: the four image-path kits must not touch networking;
/// 2 — no LLM/tagging anywhere near scoring: TaggingKit must not be imported
///     by the scoring path.
/// DESIGN.md schedules the CI grep gate for M2; it is cheap to enforce from M0.
@Suite("Source invariants (egress + tagging isolation)")
struct SourceInvariantTests {
    static let NO_NETWORK_TARGETS = ["IngestKit", "ScoringKit", "RankerKit", "ExportKit"]
    static let BANNED_NETWORK_TOKENS = ["URLSession", "import Network", "FoundationNetworking", "NWConnection"]
    static let SCORING_PATH_TARGETS = ["KeepersCore", "ScoringKit", "RankerKit"]

    private var sourcesRoot: URL {
        // Tests/InvariantTests/<this file> → repo root is two directories up.
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources")
    }

    private func swiftSources(in target: String) throws -> [(name: String, content: String)] {
        let directory = sourcesRoot.appendingPathComponent(target)
        let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil)
        var sources: [(String, String)] = []
        while let entry = enumerator?.nextObject() as? URL {
            guard entry.pathExtension == "swift" else { continue }
            let content = try String(contentsOf: entry, encoding: .utf8)
            sources.append((entry.lastPathComponent, content))
        }
        return sources
    }

    @Test("invariant 1: image-path kits contain no networking symbols")
    func noNetworkingInImagePathKits() throws {
        for target in Self.NO_NETWORK_TARGETS {
            let sources = try swiftSources(in: target)
            #expect(!sources.isEmpty, "expected Swift sources in \(target)")
            for (file, content) in sources {
                for token in Self.BANNED_NETWORK_TOKENS {
                    #expect(
                        !content.contains(token),
                        "\(target)/\(file) references banned networking token '\(token)'"
                    )
                }
            }
        }
    }

    @Test("invariant 2: the scoring path never imports TaggingKit")
    func taggingKitIsolatedFromScoringPath() throws {
        for target in Self.SCORING_PATH_TARGETS {
            for (file, content) in try swiftSources(in: target) {
                #expect(
                    !content.contains("TaggingKit"),
                    "\(target)/\(file) must not reference TaggingKit"
                )
            }
        }
    }
}
