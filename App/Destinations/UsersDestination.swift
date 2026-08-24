import Navigation

/// Defines public entry points into the Users feature. Owned by the App,
/// not by Users — Users never imports or constructs this type itself.
public enum UsersDestination: NavigationDestination {
    /// - Parameter onDetailAction: Called by the Users detail screen's own
    ///   view model when its own action happens — independent of navigation
    ///   or pop timing. `nil` for anything that can't supply one, e.g. a
    ///   real OS deep link resolved from a URL.
    case details(id: Int, onDetailAction: ActionCallback<Void>? = nil)

    /// Convenience for callers that just want to pass a closure directly.
    public static func details(id: Int, onDetailAction: @escaping () -> Void) -> UsersDestination {
        .details(id: id, onDetailAction: ActionCallback(onDetailAction))
    }
}
