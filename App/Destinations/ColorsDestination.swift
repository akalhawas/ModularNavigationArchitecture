import Navigation

/// Defines public entry points into the Colors feature. Owned by the App,
/// not by Colors — Colors never imports or constructs this type itself.
public enum ColorsDestination: NavigationDestination {
    case details(id: Int)
}
