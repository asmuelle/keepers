#if canImport(SwiftUI)
    import KeepersCore
    import SwiftUI

    /// One frame on the light table: a score card, not a fake photo. Luminance
    /// tracks the composite score; verdicts ring the tile in safelight amber
    /// (pick) or brick (reject) — color used semantically, never decoratively.
    struct FrameTile: View {
        let ranked: CullSessionViewModel.RankedFrame
        let verdict: Verdict?
        let onPick: () -> Void
        let onReject: () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                scoreWell
                metadata
            }
            .background(DarkroomColor.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: DarkroomMetrics.tileCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DarkroomMetrics.tileCornerRadius)
                    .strokeBorder(verdictColor, lineWidth: verdict == nil ? 0 : 2)
            )
        }

        private var scoreWell: some View {
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(DarkroomColor.textPrimary.opacity(0.04 + 0.30 * ranked.card.compositeScore))
                    .frame(height: 84)
                if hasBlink {
                    Text("EYES CLOSED")
                        .font(DarkroomType.data(9))
                        .foregroundStyle(DarkroomColor.surface)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(DarkroomColor.brick)
                        .padding(4)
                }
            }
            .overlay(alignment: .bottomLeading) {
                Text(String(format: "%.3f", ranked.card.compositeScore))
                    .font(DarkroomType.data(22))
                    .foregroundStyle(DarkroomColor.textPrimary)
                    .padding(6)
            }
        }

        private var metadata: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(ranked.frame.relativePath)
                    .font(DarkroomType.data(11))
                    .foregroundStyle(DarkroomColor.textSecondary)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text("F\(ranked.card.faceCount)")
                    if ranked.card.isUtility {
                        Text("UTIL").foregroundStyle(DarkroomColor.brick)
                    }
                    Spacer()
                    Button(action: onPick) {
                        Image(systemName: verdict == .pick ? "checkmark.circle.fill" : "checkmark.circle")
                    }
                    .foregroundStyle(DarkroomColor.safelight)
                    Button(action: onReject) {
                        Image(systemName: verdict == .reject ? "xmark.circle.fill" : "xmark.circle")
                    }
                    .foregroundStyle(DarkroomColor.brick)
                }
                .font(DarkroomType.data(11))
                .foregroundStyle(DarkroomColor.textSecondary)
                .buttonStyle(.plain)
            }
            .padding(8)
        }

        private var hasBlink: Bool {
            ranked.card.faces.contains(where: \.isBlinking)
        }

        private var verdictColor: Color {
            switch verdict {
            case .pick: DarkroomColor.safelight
            case .reject: DarkroomColor.brick
            case .maybe, .none: .clear
            }
        }
    }
#endif
