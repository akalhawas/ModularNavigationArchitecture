//
//  ColorsDeepLinkMapper.swift
//  Colors
//
//  Created by ali alhawas on 24/08/2026.
//

import Foundation
import Navigation

struct ColorsDeepLinkMapper: DeepLinkMapper {

    // xcrun simctl openurl booted "com.ali.modularnavigationexample://colors/details?id=1"

    func map(url: URL) -> AnyRoute? {
        guard url.host == "colors" else { return nil }

        switch url.path {
        case "/details":
            guard let id = url.queryItem("id").flatMap(Int.init) else { return nil }
            return AnyRoute(ColorsRoute.colorDetail(id: id))
        default:
            return nil
        }
    }
}
