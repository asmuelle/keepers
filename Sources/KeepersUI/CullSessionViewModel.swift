import ExportKit
import Foundation
import KeepersCore
import Observation
import ScoringKit

/// Drives the M1 slice: frames → thermal-aware batch scoring → ranked grid →
/// pick/reject → XMP sidecar content. All engine work goes through protocol
/// seams (`FrameAnalyzing`, `ThermalStateProviding`), so the same view model
/// runs the deterministic demo today and the live Vision path on device.
@MainActor
@Observable
public final class CullSessionViewModel {
    public enum Phase: Equatable {
        case idle
        case scoring(done: Int, total: Int)
        case ready
        case pausedAtCritical
    }

    public struct RankedFrame: Equatable, Identifiable {
        public let frame: Frame
        public let card: ScoreCard

        public var id: FrameID {
            frame.id
        }
    }

    public struct SidecarPreview: Equatable, Identifiable {
        public let fileName: String
        public let xmp: String

        public var id: String {
            fileName
        }
    }

    public private(set) var phase: Phase = .idle
    public private(set) var rankedFrames: [RankedFrame] = []
    public private(set) var decisions = DecisionLog()
    public private(set) var errorMessage: String?
    public let sessionName: String

    private let scorables: [ScorableFrame]
    private let scheduler: BatchScheduler
    private let mapping: ExportMapping
    private let now: @Sendable () -> Date
    private var cardsByID: [FrameID: ScoreCard] = [:]
    private let framesByID: [FrameID: Frame]

    public init(
        sessionName: String,
        scorables: [ScorableFrame],
        analyzer: any FrameAnalyzing,
        thermal: any ThermalStateProviding,
        mapping: ExportMapping = .DEFAULT,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.sessionName = sessionName
        self.scorables = scorables
        self.mapping = mapping
        self.now = now
        framesByID = Dictionary(uniqueKeysWithValues: scorables.map { ($0.frame.id, $0.frame) })
        scheduler = BatchScheduler(
            analyzer: analyzer,
            thermal: thermal,
            modelVersion: .VISION_ONLY_M1,
            now: now
        )
    }

    public func startScoring() async {
        guard phase == .idle else { return }
        let total = scorables.count
        phase = .scoring(done: 0, total: total)
        do {
            let outcome = try await scheduler.run(scorables) { [weak self] card in
                await self?.commit(card, total: total)
            }
            switch outcome {
            case .completed:
                phase = .ready
            case .pausedAtCritical:
                phase = .pausedAtCritical
            }
        } catch {
            errorMessage = "Scoring failed: \(error)"
            phase = .ready
        }
    }

    public func record(_ verdict: Verdict, for frameID: FrameID) {
        do {
            let decision = try CullDecision(
                frameID: frameID,
                verdict: verdict,
                starRating: starRating(for: verdict),
                decidedBy: .user,
                decidedAt: now()
            )
            decisions = decisions.appending(decision)
        } catch {
            errorMessage = "Could not record decision: \(error)"
        }
    }

    public func verdict(for frameID: FrameID) -> Verdict? {
        decisions.latestDecision(for: frameID)?.verdict
    }

    /// The sidecars an export would write next to the RAWs (the device build
    /// hands these to `SidecarWriter` under the security-scoped bookmark; the
    /// demo shows them so the round-trip is inspectable).
    public func sidecarPreviews() -> [SidecarPreview] {
        let writer = SidecarWriter()
        let latest = decisions.latestDecisions().values.sorted { $0.frameID < $1.frameID }
        return latest.compactMap { decision in
            guard let frame = framesByID[decision.frameID] else { return nil }
            do {
                let sidecar = try mapping.sidecar(for: decision.verdict)
                let url = writer.sidecarURL(forRawAt: URL(fileURLWithPath: frame.relativePath))
                return SidecarPreview(fileName: url.lastPathComponent, xmp: sidecar.serialized())
            } catch {
                errorMessage = "Could not build sidecar for \(frame.relativePath): \(error)"
                return nil
            }
        }
    }

    private func commit(_ card: ScoreCard, total: Int) {
        cardsByID[card.frameID] = card
        if case let .scoring(done, _) = phase {
            phase = .scoring(done: done + 1, total: total)
        }
        rankedFrames = Ranking.rankedFrameIDs(of: Array(cardsByID.values)).compactMap { id in
            guard let frame = framesByID[id], let frameCard = cardsByID[id] else { return nil }
            return RankedFrame(frame: frame, card: frameCard)
        }
    }

    private func starRating(for verdict: Verdict) -> Int {
        switch verdict {
        case .pick: mapping.pickRating
        case .reject: mapping.rejectRating
        case .maybe: mapping.maybeRating
        }
    }
}
