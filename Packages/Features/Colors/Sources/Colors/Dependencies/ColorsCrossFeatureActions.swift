import Navigation

/// The one outbound cross-feature seam Colors exposes, named for what
/// Colors itself needs — not for whichever feature actually handles it.
/// The App supplies the real implementation at `ColorsModule.register`.
public struct ColorsCrossFeatureActions {
    public let onSecondaryAction: (NavigationCoordinator, Int, @escaping () -> Void) -> Void

    public init(onSecondaryAction: @escaping (NavigationCoordinator, Int, @escaping () -> Void) -> Void) {
        self.onSecondaryAction = onSecondaryAction
    }
}
