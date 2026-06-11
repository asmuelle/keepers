import KeepersCore
import ScoringKit
import Testing

@Suite("Deterministic mock analyzer")
struct MockFrameAnalyzerTests {
    private func frame(_ name: String) -> Frame {
        Frame(id: FrameID(name), relativePath: name, fileType: .cr3)
    }

    private let preview = PreviewData(imageData: .init(), pixelWidth: 1, pixelHeight: 1)

    @Test("same frame yields the identical analysis on every call")
    func deterministicAcrossCalls() async throws {
        let analyzer = MockFrameAnalyzer()
        let first = try await analyzer.analyze(frame: frame("IMG_0001.cr3"), preview: preview)
        let second = try await analyzer.analyze(frame: frame("IMG_0001.cr3"), preview: preview)
        #expect(first == second)
    }

    @Test("different frames yield different feature prints")
    func differsAcrossFrames() async throws {
        let analyzer = MockFrameAnalyzer()
        let first = try await analyzer.analyze(frame: frame("IMG_0001.cr3"), preview: preview)
        let second = try await analyzer.analyze(frame: frame("IMG_0002.cr3"), preview: preview)
        #expect(first.featurePrint != second.featurePrint)
    }

    @Test("outputs stay within the platform ranges")
    func outputRanges() async throws {
        let analyzer = MockFrameAnalyzer()
        for index in 0 ..< 50 {
            let analysis = try await analyzer.analyze(frame: frame("IMG_\(index).cr3"), preview: preview)
            if let aesthetics = analysis.aestheticsScore {
                #expect(aesthetics >= -1 && aesthetics <= 1)
            }
            for face in analysis.faces {
                if let quality = face.captureQuality {
                    #expect(quality >= 0 && quality <= 1)
                }
            }
        }
    }
}
