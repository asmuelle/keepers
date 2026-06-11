import KeepersCore
import Testing

@Suite("StableHash (FNV-1a)")
struct StableHashTests {
    @Test("matches published FNV-1a test vectors")
    func knownVectors() {
        #expect(StableHash.fnv1a("") == 0xCBF2_9CE4_8422_2325)
        #expect(StableHash.fnv1a("a") == 0xAF63_DC4C_8601_EC8C)
    }

    @Test("is deterministic across invocations")
    func deterministic() {
        #expect(StableHash.fnv1a("IMG_0001.cr3") == StableHash.fnv1a("IMG_0001.cr3"))
        #expect(StableHash.unit("IMG_0001.cr3", salt: "s") == StableHash.unit("IMG_0001.cr3", salt: "s"))
    }

    @Test("unit values stay in [0, 1) and respond to salt")
    func unitRangeAndSalt() {
        let first = StableHash.unit("frame", salt: "a")
        let second = StableHash.unit("frame", salt: "b")
        #expect(first >= 0 && first < 1)
        #expect(second >= 0 && second < 1)
        #expect(first != second)
    }
}
