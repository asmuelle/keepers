import KeepersUI
import SwiftUI

/// Composition root only — no logic (DESIGN.md module map). The M1 shell runs
/// the demo session: the real engine through the deterministic mock providers,
/// fully on-device, zero network. Card ingest via the document picker wires in
/// here once device acceptance starts.
@main
struct KeepersApp: App {
    var body: some Scene {
        WindowGroup {
            KeepersRootView(viewModel: DemoSession.makeViewModel())
        }
    }
}
