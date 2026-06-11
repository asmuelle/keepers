import ScoringKit
import Testing

@Suite("Scheduler thermal policy (invariant 7)")
struct SchedulerPolicyTests {
    @Test("nominal full width, fair halved, serious single-stream, critical paused")
    func concurrencyLadder() {
        #expect(SchedulerPolicy.concurrency(for: .nominal, nominalWidth: 4) == 4)
        #expect(SchedulerPolicy.concurrency(for: .fair, nominalWidth: 4) == 2)
        #expect(SchedulerPolicy.concurrency(for: .serious, nominalWidth: 4) == 1)
        #expect(SchedulerPolicy.concurrency(for: .critical, nominalWidth: 4) == 0)
    }

    @Test("width never drops below 1 except at critical")
    func minimumWidth() {
        #expect(SchedulerPolicy.concurrency(for: .nominal, nominalWidth: 1) == 1)
        #expect(SchedulerPolicy.concurrency(for: .fair, nominalWidth: 1) == 1)
        #expect(SchedulerPolicy.concurrency(for: .critical, nominalWidth: 1) == 0)
    }
}
