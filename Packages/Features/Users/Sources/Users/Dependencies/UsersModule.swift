import SwiftUI
import NetworkService
import Navigation
import Combine

/// Resolves this feature's dependencies without callers having to build
/// `UsersDependencies` themselves at every navigation site.
///
/// Must be configured once at app launch (see `AppComposition.bootstrapFeatures`)
/// before any `UsersRoute` is navigated to.
@MainActor
public enum UsersModule {

    static var viewModels: () -> UsersViewModels = {
        fatalError("UsersModule not registered — call UsersModule.register(network:) at app launch")
    }

    public static func register(network: NetworkService) {
        let dependencies = UsersDependencies(network: network)
        viewModels = { dependencies.viewModels }
        registerRouting()
    }
    
    private static func registerRouting() {
        DeepLinkRouter.shared.register(UsersDeepLinkMapper())
    }
}

// MARK: Shared Views
extension UsersModule {
    @ViewBuilder
    public static func headerHomeView(items: Int) -> some View {
        LatestUsersView(viewModel: viewModels().makeLatestUsersViewModel(limit: items))
    }

    @ViewBuilder
    public static func makeServicesCard() -> some View {
        UsersServiceCard()
    }
}
