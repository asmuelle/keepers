#if canImport(SwiftUI)
    import KeepersCore
    import SwiftUI

    /// Root of the app shell: darkroom chrome wrapping the cull grid.
    public struct KeepersRootView: View {
        @State private var viewModel: CullSessionViewModel

        public init(viewModel: CullSessionViewModel) {
            _viewModel = State(initialValue: viewModel)
        }

        public var body: some View {
            NavigationStack {
                CullGridView(viewModel: viewModel)
                    .background(DarkroomColor.surface.ignoresSafeArea())
            }
            .preferredColorScheme(.dark)
            .tint(DarkroomColor.safelight)
            .task { await viewModel.startScoring() }
        }
    }
#endif
