#if canImport(SwiftUI)
    import KeepersCore
    import SwiftUI

    /// Ranked shortlist grid: the photographer reviews from the top of the stack
    /// while the tail may still be scoring (DESIGN hero flow).
    struct CullGridView: View {
        let viewModel: CullSessionViewModel
        @State private var isExportPresented = false

        private let columns = [
            GridItem(.adaptive(minimum: DarkroomMetrics.tileMinWidth), spacing: DarkroomMetrics.gridSpacing)
        ]

        var body: some View {
            ScrollView {
                header
                Rectangle()
                    .fill(DarkroomColor.hairline)
                    .frame(height: DarkroomMetrics.hairlineWidth)
                    .padding(.horizontal)
                LazyVGrid(columns: columns, spacing: DarkroomMetrics.gridSpacing) {
                    ForEach(viewModel.rankedFrames) { ranked in
                        FrameTile(
                            ranked: ranked,
                            verdict: viewModel.verdict(for: ranked.id),
                            onPick: { viewModel.record(.pick, for: ranked.id) },
                            onReject: { viewModel.record(.reject, for: ranked.id) }
                        )
                    }
                }
                .padding()
            }
            .background(DarkroomColor.surface)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Export XMP") { isExportPresented = true }
                        .font(DarkroomType.data(13))
                        .disabled(viewModel.decisions.entries.isEmpty)
                }
            }
            .sheet(isPresented: $isExportPresented) {
                SidecarListView(previews: viewModel.sidecarPreviews())
            }
        }

        private var header: some View {
            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.sessionName.uppercased())
                    .font(DarkroomType.heading(28))
                    .foregroundStyle(DarkroomColor.textPrimary)
                Text(phaseLine)
                    .font(DarkroomType.data(13))
                    .foregroundStyle(phaseColor)
                if let message = viewModel.errorMessage {
                    Text(message)
                        .font(DarkroomType.data(12))
                        .foregroundStyle(DarkroomColor.brick)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }

        private var phaseLine: String {
            switch viewModel.phase {
            case .idle:
                "READY TO SCORE"
            case let .scoring(done, total):
                "SCORING \(done)/\(total) · MOCK PIPELINE · ON-DEVICE"
            case .ready:
                "RANKED \(viewModel.rankedFrames.count) FRAMES · \(ModelVersion.VISION_ONLY_M1.rawValue)"
            case .pausedAtCritical:
                "PAUSED — THERMAL CRITICAL · PROGRESS CHECKPOINTED"
            }
        }

        private var phaseColor: Color {
            viewModel.phase == .pausedAtCritical ? DarkroomColor.brick : DarkroomColor.safelight
        }
    }
#endif
