#if canImport(SwiftUI)
    import SwiftUI

    /// "Darkroom light-table" tokens (DESIGN.md visual direction): true-black
    /// chrome and color-neutral near-blacks so previews read color-true, one
    /// safelight-amber accent for picks/progress/focus, desaturated brick for
    /// rejects. White is reserved for image content and primary numerals.
    /// Hierarchy comes from scale and luminance — hairlines, no cards, no shadows.
    public enum DarkroomColor {
        /// Pure OLED black surface.
        public static let surface = Color.black
        /// oklch(0.16 0 0) — neutral near-black raised band.
        public static let surfaceRaised = Color(red: 0.106, green: 0.106, blue: 0.106)
        /// oklch(0.30 0 0) — hairline separators.
        public static let hairline = Color(red: 0.227, green: 0.227, blue: 0.227)
        /// oklch(0.78 0.16 75) — safelight amber.
        public static let safelight = Color(red: 0.918, green: 0.643, blue: 0.247)
        /// Desaturated brick red — rejects only, never decoration.
        public static let brick = Color(red: 0.667, green: 0.290, blue: 0.224)
        public static let textPrimary = Color.white
        public static let textSecondary = Color(white: 0.62)
    }

    public enum DarkroomType {
        /// Heavy, tight headings (SF Pro Display via the system stack).
        public static func heading(_ size: CGFloat) -> Font {
            .system(size: size, weight: .heavy, design: .default)
        }

        /// SF Mono for EXIF, scores, and EAR readouts — data the photographer
        /// scans like a histogram.
        public static func data(_ size: CGFloat) -> Font {
            .system(size: size, weight: .medium, design: .monospaced)
        }
    }

    public enum DarkroomMetrics {
        public static let hairlineWidth: CGFloat = 1
        public static let tileCornerRadius: CGFloat = 2
        public static let gridSpacing: CGFloat = 10
        public static let tileMinWidth: CGFloat = 150
    }
#endif
