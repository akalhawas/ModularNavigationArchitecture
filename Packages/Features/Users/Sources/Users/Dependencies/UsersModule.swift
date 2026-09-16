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
    }
}

// MARK: API
extension UsersModule {
    public static func latestUsersView(items: Int) -> some View {
        LatestUsersView(viewModel: viewModels().makeLatestColorsViewModel(limit: items))
    }

    public static func makeServicesCard() -> some View {
        UsersServiceCard()
    }
}
