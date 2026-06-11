import Foundation
import KeepersCore
import ScoringKit
import Synchronization
import Testing

/// Pops a scripted sequence of thermal states; falls back when exhausted.
private final class ScriptedThermalProvider: ThermalStateProviding, Sendable {
    private let states: Mutex<[ThermalState]>
    private let fallback: ThermalState

    init(_ sequence: [ThermalState], fallback: ThermalState) {
        states = Mutex(sequence)
        self.fallback = fallback
    }

    func currentState() -> ThermalState {
        states.withLock { remaining in
            remaining.isEmpty ? fallback : remaining.removeFirst()
        }
    }
}

private actor CardCollector {
    private(set) var cards: [ScoreCard] = []

    func add(_ card: ScoreCard) {
        cards.append(card)
    }
}

@Suite("Thermal-aware batch scheduler (invariants 6 + 7)")
struct BatchSchedulerTests {
    private let fixedDate = Date(timeIntervalSince1970: 1_750_000_000)

    private func scorables(_ count: Int) -> [ScorableFrame] {
        (1 ... count).map { index in
            let name = String(format: "IMG_%03d.cr3", index)
            return ScorableFrame(
                frame: Frame(id: FrameID(name), relativePath: name, fileType: .cr3),
                preview: PreviewData(imageData: Data(name.utf8), pixelWidth: 1, pixelHeight: 1)
            )
        }
    }

    private func makeScheduler(thermal: any ThermalStateProviding) -> BatchScheduler {
        BatchScheduler(
            analyzer: MockFrameAnalyzer(),
            thermal: thermal,
            modelVersion: .VISION_ONLY_M1,
            now: { [fixedDate] in fixedDate }
        )
    }

    @Test("scores every frame at nominal and commits in deterministic order")
    func completesAtNominal() async throws {
        // Arrange
        let frames = scorables(7)
        let collector = CardCollector()
        let scheduler = makeScheduler(thermal: FixedThermalProvider(.nominal))

        // Act
        let outcome = try await scheduler.run(frames) { await collector.add($0) }

        // Assert
        #expect(outcome == .completed(framesScored: 7))
        let committed = await collector.cards.map(\.frameID)
        #expect(committed == frames.map(\.frame.id))
    }

    @Test("critical thermal state checkpoints and pauses instead of pushing on")
    func pausesAtCritical() async throws {
        // Arrange: one nominal batch (4 frames), then critical
        let frames = scorables(7)
        let collector = CardCollector()
        let thermal = ScriptedThermalProvider([.nominal], fallback: .critical)
        let scheduler = makeScheduler(thermal: thermal)

        // Act
        let outcome = try await scheduler.run(frames) { await collector.add($0) }

        // Assert: progress is durable — exactly the first batch was committed
        let committed = await collector.cards.map(\.frameID)
        #expect(committed == frames.prefix(4).map(\.frame.id))
        #expect(outcome == .pausedAtCritical(BatchCheckpoint(completedFrameIDs: Set(committed))))
    }

    @Test("resuming from a checkpoint finishes the tail without re-scoring")
    func resumesFromCheckpoint() async throws {
        // Arrange: a checkpoint that already covers the first 4 frames
        let frames = scorables(7)
        let checkpoint = BatchCheckpoint(completedFrameIDs: Set(frames.prefix(4).map(\.frame.id)))
        let collector = CardCollector()
        let scheduler = makeScheduler(thermal: FixedThermalProvider(.nominal))

        // Act
        let outcome = try await scheduler.run(frames, resumingFrom: checkpoint) { await collector.add($0) }

        // Assert: only the remaining 3 frames were scored
        #expect(outcome == .completed(framesScored: 3))
        let committed = await collector.cards.map(\.frameID)
        #expect(committed == frames.suffix(3).map(\.frame.id))
    }

    @Test("serious thermal state degrades to single-stream batches")
    func singleStreamAtSerious() async throws {
        // Arrange: one serious poll (width 1), then critical → exactly 1 frame scored
        let frames = scorables(5)
        let collector = CardCollector()
        let thermal = ScriptedThermalProvider([.serious], fallback: .critical)
        let scheduler = makeScheduler(thermal: thermal)

        // Act
        let outcome = try await scheduler.run(frames) { await collector.add($0) }

        // Assert
        let committed = await collector.cards
        #expect(committed.count == 1)
        #expect(outcome == .pausedAtCritical(BatchCheckpoint(completedFrameIDs: [frames[0].frame.id])))
    }

    @Test("fair thermal state halves the batch width")
    func halvedWidthAtFair() async throws {
        // Arrange: one fair poll (width 2), then critical → exactly 2 frames scored
        let frames = scorables(5)
        let collector = CardCollector()
        let thermal = ScriptedThermalProvider([.fair], fallback: .critical)
        let scheduler = makeScheduler(thermal: thermal)

        // Act
        _ = try await scheduler.run(frames) { await collector.add($0) }

        // Assert
        let committed = await collector.cards
        #expect(committed.count == 2)
    }

    @Test("re-running the same frames yields identical score cards (invariant 6)")
    func deterministicRescore() async throws {
        // Arrange
        let frames = scorables(6)
        let firstCollector = CardCollector()
        let secondCollector = CardCollector()

        // Act: two independent runs with fixed clock and same model version
        _ = try await makeScheduler(thermal: FixedThermalProvider(.nominal))
            .run(frames) { await firstCollector.add($0) }
        _ = try await makeScheduler(thermal: FixedThermalProvider(.nominal))
            .run(frames) { await secondCollector.add($0) }

        // Assert
        let first = await firstCollector.cards
        let second = await secondCollector.cards
        #expect(first == second)
    }
}
