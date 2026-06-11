#if canImport(SwiftUI)
    import SwiftUI

    /// Shows the exact XMP sidecar content an export writes next to the RAWs.
    /// Honest semantics (invariant 8): stars and color labels only — Lightroom
    /// pick/reject flags are catalog-only and do not survive XMP.
    struct SidecarListView: View {
        let previews: [CullSessionViewModel.SidecarPreview]

        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Stars + color labels only. Lightroom pick/reject flags are catalog-only and do not survive XMP.")
                            .font(DarkroomType.data(12))
                            .foregroundStyle(DarkroomColor.textSecondary)
                        ForEach(previews) { preview in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(preview.fileName)
                                    .font(DarkroomType.data(13))
                                    .foregroundStyle(DarkroomColor.safelight)
                                Text(preview.xmp)
                                    .font(DarkroomType.data(10))
                                    .foregroundStyle(DarkroomColor.textPrimary)
                                    .textSelection(.enabled)
                                    .padding(8)
                                    .background(DarkroomColor.surfaceRaised)
                            }
                        }
                    }
                    .padding()
                }
                .background(DarkroomColor.surface)
                .navigationTitle("XMP Export")
            }
            .preferredColorScheme(.dark)
        }
    }
#endif
