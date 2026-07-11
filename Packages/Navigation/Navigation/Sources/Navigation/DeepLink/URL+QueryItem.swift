//
//  File.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 30/05/2026.
//

import SwiftUI

public extension URL {

    /// Returns the value of a query parameter.
    ///
    /// - Parameter name: The name of the query parameter.
    /// - Returns: The parameter value if it exists; otherwise, `nil`.
    func queryItem(_ name: String) -> String? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == name })?
            .value
    }
}
