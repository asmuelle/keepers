import Foundation

public enum BurstDefaults {
    /// Maximum capture-time gap between consecutive frames of one burst.
    public static let MAX_GAP_SECONDS = 1.0
    /// Maximum feature-print cosine distance between consecutive burst frames.
    public static let MAX_PRINT_DISTANCE = 0.35
}

/// Input for burst grouping. `bestnessScore` is whatever the caller deems
/// comparable WITHIN one burst (per-face capture quality is only valid for the
/// same subject — platform contract — which a burst satisfies by construction).
public struct BurstCandidate: Sendable, Equatable {
    public let id: FrameID
    public let captureDate: Date
    public let print: FeaturePrintVector?
    public let bestnessScore: Double

    public init(id: FrameID, captureDate: Date, print: FeaturePrintVector?, bestnessScore: Double) {
        self.id = id
        self.captureDate = captureDate
        self.print = print
        self.bestnessScore = bestnessScore
    }
}

public struct BurstGroup: Sendable, Equatable {
    /// Members in capture order.
    public let memberIDs: [FrameID]
    public let suggestedBestID: FrameID

    public init(memberIDs: [FrameID], suggestedBestID: FrameID) {
        self.memberIDs = memberIDs
        self.suggestedBestID = suggestedBestID
    }
}

public enum BurstGrouper {
    /// Groups by capture-time adjacency AND feature-print similarity.
    /// Frames lacking a print join on time alone. Only runs of ≥ 2 frames are
    /// bursts. Deterministic: input is sorted by (captureDate, id) first.
    public static func bursts(
        in candidates: [BurstCandidate],
        maxGap: TimeInterval = BurstDefaults.MAX_GAP_SECONDS,
        maxPrintDistance: Double = BurstDefaults.MAX_PRINT_DISTANCE
    ) -> [BurstGroup] {
        let sorted = candidates.sorted {
            ($0.captureDate, $0.id) < ($1.captureDate, $1.id)
        }
        var runs: [[BurstCandidate]] = []
        for candidate in sorted {
            if let previous = runs.last?.last,
               isAdjacent(previous, candidate, maxGap: maxGap, maxPrintDistance: maxPrintDistance)
            {
                runs[runs.count - 1].append(candidate)
            } else {
                runs.append([candidate])
            }
        }
        return runs.filter { $0.count >= 2 }.map(makeGroup(from:))
    }

    private static func isAdjacent(
        _ previous: BurstCandidate,
        _ next: BurstCandidate,
        maxGap: TimeInterval,
        maxPrintDistance: Double
    ) -> Bool {
        guard next.captureDate.timeIntervalSince(previous.captureDate) <= maxGap else { return false }
        guard let lhs = previous.print, let rhs = next.print else { return true }
        guard let distance = try? VectorMath.cosineDistance(lhs, rhs) else { return false }
        return distance <= maxPrintDistance
    }

    private static func makeGroup(from run: [BurstCandidate]) -> BurstGroup {
        // Best = highest bestness; tie → lowest FrameID, so the pick is stable.
        let best = run.max {
            ($0.bestnessScore, $1.id) < ($1.bestnessScore, $0.id)
        }
        return BurstGroup(memberIDs: run.map(\.id), suggestedBestID: best?.id ?? run[0].id)
    }
}
