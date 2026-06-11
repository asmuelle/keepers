import Foundation
import KeepersCore

/// Durable progress marker: which frames already have committed ScoreCards.
public struct BatchCheckpoint: Sendable, Equatable {
    public let completedFrameIDs: Set<FrameID>

    public init(completedFrameIDs: Set<FrameID> = []) {
        self.completedFrameIDs = completedFrameIDs
    }
}

public enum BatchOutcome: Sendable, Equatable {
    case completed(framesScored: Int)
    case pausedAtCritical(BatchCheckpoint)
}

/// Thermal-aware batch scheduler (invariant 7): nominal → full width,
/// fair → half, serious → single-stream, critical → checkpoint + pause.
/// Progress is durable (DESIGN flow 5): every ScoreCard is handed to `onScore`
/// as its batch commits, so a pause, yanked cable, or kill resumes from the
/// checkpoint without re-scoring.
public actor BatchScheduler {
    private let analyzer: any FrameAnalyzing
    private let thermal: any ThermalStateProviding
    private let modelVersion: ModelVersion
    private let nominalWidth: Int
    private let now: @Sendable () -> Date

    public init(
        analyzer: any FrameAnalyzing,
        thermal: any ThermalStateProviding,
        modelVersion: ModelVersion,
        nominalWidth: Int = SchedulerPolicy.NOMINAL_CONCURRENCY,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.analyzer = analyzer
        self.thermal = thermal
        self.modelVersion = modelVersion
        self.nominalWidth = nominalWidth
        self.now = now
    }

    public func run(
        _ frames: [ScorableFrame],
        resumingFrom checkpoint: BatchCheckpoint = BatchCheckpoint(),
        onScore: @Sendable (ScoreCard) async -> Void
    ) async throws -> BatchOutcome {
        var completed = checkpoint.completedFrameIDs
        var remaining = frames.filter { !completed.contains($0.frame.id) }
        var scoredCount = 0

        while !remaining.isEmpty {
            let width = SchedulerPolicy.concurrency(for: thermal.currentState(), nominalWidth: nominalWidth)
            guard width > 0 else {
                return .pausedAtCritical(BatchCheckpoint(completedFrameIDs: completed))
            }
            let batch = Array(remaining.prefix(width))
            for card in try await score(batch: batch) {
                await onScore(card)
                completed.insert(card.frameID)
                scoredCount += 1
            }
            remaining.removeFirst(batch.count)
        }
        return .completed(framesScored: scoredCount)
    }

    /// Scores one batch concurrently; commits in input order for determinism.
    private func score(batch: [ScorableFrame]) async throws -> [ScoreCard] {
        let analyzer = analyzer
        let version = modelVersion
        let timestamp = now()
        return try await withThrowingTaskGroup(of: (Int, FrameAnalysis).self) { group in
            for (index, item) in batch.enumerated() {
                group.addTask {
                    try await (index, analyzer.analyze(frame: item.frame, preview: item.preview))
                }
            }
            var indexed: [(Int, FrameAnalysis)] = []
            for try await result in group {
                indexed.append(result)
            }
            return indexed
                .sorted { $0.0 < $1.0 }
                .map { ScoreCardBuilder.makeScoreCard(from: $0.1, modelVersion: version, scoredAt: timestamp) }
        }
    }
}
