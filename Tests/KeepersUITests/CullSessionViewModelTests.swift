import Foundation
import IngestKit
import KeepersCore
import KeepersUI
import ScoringKit
import Testing

@MainActor
@Suite("Cull session view model — the M1 slice end to end")
struct CullSessionViewModelTests {
    private let fixedDate = Date(timeIntervalSince1970: 1_750_000_000)

    private func makeViewModel(
        frameNames: [String] = ["c.nef", "a.cr3", "b.cr3", "d.arw", "e.dng"],
        thermal: any ThermalStateProviding = FixedThermalProvider(.nominal)
    ) throws -> CullSessionViewModel {
        let extractor = MockPreviewExtractor()
        let scorables: [ScorableFrame] = try frameNames.map { name in
            let url = URL(fileURLWithPath: name)
            let fileType = try #require(RawFileType(fileExtension: url.pathExtension))
            return try ScorableFrame(
                frame: Frame(id: FrameID(name), relativePath: name, fileType: fileType),
                preview: extractor.extractEmbeddedPreview(from: url)
            )
        }
        return CullSessionViewModel(
            sessionName: "Test session",
            scorables: scorables,
            analyzer: MockFrameAnalyzer(),
            thermal: thermal,
            now: { [fixedDate] in fixedDate }
        )
    }

    @Test("scoring ranks every frame by composite, descending")
    func scoringProducesRankedGrid() async throws {
        // Arrange
        let viewModel = try makeViewModel()

        // Act
        await viewModel.startScoring()

        // Assert
        #expect(viewModel.phase == .ready)
        #expect(viewModel.rankedFrames.count == 5)
        let composites = viewModel.rankedFrames.map(\.card.compositeScore)
        #expect(composites == composites.sorted(by: >))
        #expect(viewModel.errorMessage == nil)
    }

    @Test("two sessions over the same frames rank identically (invariant 6)")
    func deterministicRanking() async throws {
        let first = try makeViewModel()
        let second = try makeViewModel()
        await first.startScoring()
        await second.startScoring()
        #expect(first.rankedFrames.map(\.id) == second.rankedFrames.map(\.id))
    }

    @Test("pick then reject supersedes without losing history")
    func verdictsSupersede() async throws {
        // Arrange
        let viewModel = try makeViewModel()
        await viewModel.startScoring()
        let target = try #require(viewModel.rankedFrames.first?.id)

        // Act
        viewModel.record(.pick, for: target)
        viewModel.record(.reject, for: target)

        // Assert
        #expect(viewModel.verdict(for: target) == .reject)
        #expect(viewModel.decisions.entries.count == 2)
    }

    @Test("sidecar previews carry the Lightroom mapping for every decided frame")
    func sidecarPreviewsMatchDecisions() async throws {
        // Arrange
        let viewModel = try makeViewModel()
        await viewModel.startScoring()
        viewModel.record(.pick, for: FrameID("a.cr3"))
        viewModel.record(.reject, for: FrameID("b.cr3"))

        // Act
        let previews = viewModel.sidecarPreviews()

        // Assert: sorted by frame id; pick → Rating 3, reject → Red + 1
        #expect(previews.map(\.fileName) == ["a.xmp", "b.xmp"])
        #expect(previews[0].xmp.contains("xmp:Rating=\"3\""))
        #expect(!previews[0].xmp.contains("xmp:Label"))
        #expect(previews[1].xmp.contains("xmp:Rating=\"1\""))
        #expect(previews[1].xmp.contains("xmp:Label=\"Red\""))
    }

    @Test("critical thermal state pauses scoring with checkpointed progress")
    func criticalThermalPauses() async throws {
        // Arrange
        let viewModel = try makeViewModel(thermal: FixedThermalProvider(.critical))

        // Act
        await viewModel.startScoring()

        // Assert
        #expect(viewModel.phase == .pausedAtCritical)
        #expect(viewModel.rankedFrames.isEmpty)
    }

    @Test("demo session composes 24 deterministic frames")
    func demoSessionComposes() {
        let names = DemoSession.frameNames()
        #expect(names.count == 24)
        #expect(names == DemoSession.frameNames())
        let viewModel = DemoSession.makeViewModel()
        #expect(viewModel.phase == .idle)
    }
}
