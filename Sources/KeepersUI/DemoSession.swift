import Foundation
import IngestKit
import KeepersCore
import ScoringKit

/// Composition helper for the demo session: the full M1 pipeline running on
/// the deterministic mock providers. No image assets, no model, no network —
/// the same frames score identically on every launch.
public enum DemoSession {
    static let FRAME_COUNT = 24
    static let EXTENSIONS = ["cr3", "nef", "arw", "dng", "jpeg"]

    public static func frameNames() -> [String] {
        (1 ... FRAME_COUNT).map { index in
            String(format: "KPR_%04d.%@", index, EXTENSIONS[(index - 1) % EXTENSIONS.count])
        }
    }

    @MainActor
    public static func makeViewModel() -> CullSessionViewModel {
        let extractor = MockPreviewExtractor()
        var scorables: [ScorableFrame] = []
        for name in frameNames() {
            guard let fileType = RawFileType(fileExtension: URL(fileURLWithPath: name).pathExtension) else {
                continue
            }
            let frame = Frame(id: FrameID(name), relativePath: name, fileType: fileType)
            do {
                let preview = try extractor.extractEmbeddedPreview(from: URL(fileURLWithPath: name))
                scorables.append(ScorableFrame(frame: frame, preview: preview))
            } catch {
                continue // mock extraction cannot fail; skip defensively rather than crash
            }
        }
        return CullSessionViewModel(
            sessionName: "Demo session",
            scorables: scorables,
            analyzer: MockFrameAnalyzer(),
            thermal: ProcessInfoThermalProvider()
        )
    }
}
