/// Pure concurrency policy for the batch scheduler (invariant 7):
/// full tilt at nominal, halved at fair, single-stream at serious,
/// paused (0) at critical.
public enum SchedulerPolicy {
    public static let NOMINAL_CONCURRENCY = 4

    public static func concurrency(
        for state: ThermalState,
        nominalWidth: Int = NOMINAL_CONCURRENCY
    ) -> Int {
        switch state {
        case .nominal: max(1, nominalWidth)
        case .fair: max(1, nominalWidth / 2)
        case .serious: 1
        case .critical: 0
        }
    }
}
