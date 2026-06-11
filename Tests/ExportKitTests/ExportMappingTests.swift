import ExportKit
import KeepersCore
import Testing

@Suite("Verdict → XMP mapping (DESIGN flow 3 defaults)")
struct ExportMappingTests {
    @Test("picks map to ★★★ with no label")
    func pickMapping() throws {
        let sidecar = try ExportMapping.DEFAULT.sidecar(for: .pick)
        #expect(sidecar.rating == 3)
        #expect(sidecar.label == nil)
    }

    @Test("rejects map to red label + ★ — never deletion (invariant 4)")
    func rejectMapping() throws {
        let sidecar = try ExportMapping.DEFAULT.sidecar(for: .reject)
        #expect(sidecar.rating == 1)
        #expect(sidecar.label == .red)
    }

    @Test("maybe maps to unrated")
    func maybeMapping() throws {
        let sidecar = try ExportMapping.DEFAULT.sidecar(for: .maybe)
        #expect(sidecar.rating == 0)
        #expect(sidecar.label == nil)
    }

    @Test("custom mappings are honored")
    func customMapping() throws {
        let mapping = ExportMapping(pickRating: 5, rejectRating: 0, rejectLabel: .purple, maybeRating: 2)
        #expect(try mapping.sidecar(for: .pick).rating == 5)
        #expect(try mapping.sidecar(for: .reject).label == .purple)
        #expect(try mapping.sidecar(for: .maybe).rating == 2)
    }
}
