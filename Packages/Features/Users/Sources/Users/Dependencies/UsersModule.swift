import NetworkService

/// Resolves this feature's dependencies without callers having to build
/// `UsersDependencies` themselves at every navigation site.
///
/// Must be configured once at app launch (see `AppComposition.bootstrapFeatures`)
/// before any `UsersRoute` is navigated to.
@MainActor
public enum UsersModule {

    static var viewModels: () -> UsersViewModels = {
        fatalError("UsersModule has not been registered.")
    }

    public static func register(network: NetworkService) {
        let dependencies = UsersDependencies(network: network)
        viewModels = { dependencies.viewModels }
    }
}
