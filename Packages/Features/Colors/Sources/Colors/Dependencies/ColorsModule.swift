import NetworkService

/// Resolves this feature's dependencies without callers having to build
/// `ColorsDependencies` themselves at every navigation site.
///
/// Must be configured once at app launch (see `AppComposition.bootstrapFeatures`)
/// before any `ColorsRoute` is navigated to.
@MainActor
public enum ColorsModule {

    static var viewModels: () -> ColorsViewModels = {
        fatalError("ColorsModule not registered — call ColorsModule.register(network:crossFeatureActions:) at app launch")
    }

    public static func register(network: NetworkService, crossFeatureActions: ColorsCrossFeatureActions) {
        let dependencies = ColorsDependencies(network: network, crossFeatureActions: crossFeatureActions)
        viewModels = { dependencies.viewModels }
    }
}
