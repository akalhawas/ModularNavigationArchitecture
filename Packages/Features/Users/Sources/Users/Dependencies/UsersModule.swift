//
//  UsersModule.swift
//  Users
//
//  Created by ali alhawas on 24/07/2026.
//

import NetworkService
import Navigation
import UsersAPI

/// Resolves this feature's dependencies without callers having to build
/// `UsersDependencies` themselves at every navigation site.
///
/// Must be configured once at app launch (see `AppBootstrap.configure()`)
/// before any `UsersRoute` is navigated to.
@MainActor
public enum UsersModule {

    static var viewModels: () -> UsersViewModels = {
        fatalError("UsersModule has not been registered.")
    }

    public static func register(network: NetworkService) {
        let dependencies = UsersDependencies(network: network)
        viewModels = { dependencies.viewModels }
        registerPublicEntryPoint()
    }

    private static func registerPublicEntryPoint() {
        // MARK: Register the public entry points
        RouteRegistry.shared.register(UsersDestination.self) { destination in
            switch destination {
            case .details(let id):
                return AnyRoute(UsersRoute.userDetail(id: id))
            }
        }
        DeepLinkRouter.shared.register(UsersDeepLinkMapper())
    }
}
