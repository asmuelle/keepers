public enum Ranking {
    /// Composite descending; ties broken by ascending FrameID. Fully
    /// deterministic (invariant 6): same cards ⇒ same ordering, every run.
    public static func rankedFrameIDs(of cards: [ScoreCard]) -> [FrameID] {
        cards
            .sorted { lhs, rhs in
                if lhs.compositeScore != rhs.compositeScore {
                    return lhs.compositeScore > rhs.compositeScore
                }
                return lhs.frameID < rhs.frameID
            }
            .map(\.frameID)
    }
}
