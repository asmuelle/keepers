/// FNV-1a 64-bit hash — deterministic across processes, runs, and machines
/// (unlike `Hasher`, which is seeded per process). Used wherever Keepers needs
/// reproducible pseudo-values, e.g. the deterministic mock analyzer.
public enum StableHash {
    public static let FNV_OFFSET_BASIS: UInt64 = 0xCBF2_9CE4_8422_2325
    public static let FNV_PRIME: UInt64 = 0x0000_0100_0000_01B3

    public static func fnv1a(_ text: String) -> UInt64 {
        var hash = FNV_OFFSET_BASIS
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* FNV_PRIME
        }
        return hash
    }

    /// Deterministic value in [0, 1) derived from `text` + `salt`.
    public static func unit(_ text: String, salt: String) -> Double {
        let hash = fnv1a(salt + ":" + text)
        let mantissa = hash >> 11 // top 53 bits fit a Double exactly
        return Double(mantissa) / Double(1 << 53)
    }
}
