//
//  TestError.swift
//  ColorsTests
//

import Foundation

enum TestError: LocalizedError, Equatable {
    case generic
    case network

    var errorDescription: String? {
        switch self {
        case .generic: return "Generic test error"
        case .network: return "Network test error"
        }
    }
}
