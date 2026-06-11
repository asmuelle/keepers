/// Input pair for clustering: a frame and its (optional) feature print.
public struct FramePrint: Sendable, Equatable {
    public let id: FrameID
    public let print: FeaturePrintVector?

    public init(id: FrameID, print: FeaturePrintVector?) {
        self.id = id
        self.print = print
    }
}

public struct DupeCluster: Sendable, Equatable {
    /// First member seen — the cluster's comparison anchor.
    public let representativeID: FrameID
    /// Members in input order; the representative is always first.
    public let memberIDs: [FrameID]

    public init(representativeID: FrameID, memberIDs: [FrameID]) {
        self.representativeID = representativeID
        self.memberIDs = memberIDs
    }
}

public enum DupeDefaults {
    /// Cosine-distance threshold below which two prints count as near-duplicates.
    public static let COSINE_DISTANCE_THRESHOLD = 0.18
}

public enum DupeClusterer {
    /// Greedy single-pass clustering by feature-print cosine distance.
    /// Deterministic for a given input order (invariant 6). Frames without a
    /// print become singleton clusters and never absorb other frames.
    public static func clusters(
        of frames: [FramePrint],
        distanceThreshold: Double = DupeDefaults.COSINE_DISTANCE_THRESHOLD
    ) -> [DupeCluster] {
        var anchors: [FeaturePrintVector?] = []
        var members: [[FrameID]] = []

        for frame in frames {
            if let index = joinableClusterIndex(for: frame.print, anchors: anchors, threshold: distanceThreshold) {
                members[index].append(frame.id)
            } else {
                anchors.append(frame.print)
                members.append([frame.id])
            }
        }
        return members.map { DupeCluster(representativeID: $0[0], memberIDs: $0) }
    }

    private static func joinableClusterIndex(
        for print: FeaturePrintVector?,
        anchors: [FeaturePrintVector?],
        threshold: Double
    ) -> Int? {
        guard let print else { return nil }
        for (index, anchor) in anchors.enumerated() {
            guard let anchor else { continue }
            guard let distance = try? VectorMath.cosineDistance(print, anchor) else { continue }
            if distance <= threshold {
                return index
            }
        }
        return nil
    }
}
