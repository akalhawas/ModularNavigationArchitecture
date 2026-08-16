//
//  ColorRepositoryImp.swift
//  Colors
//
//  Created by ali alhawas on 24/07/2026.
//

import Combine
import NetworkService

final class ColorRepositoryImp: ColorRepository {

    private let networkService: NetworkService

    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    func fetchColors(page: Int) -> AnyPublisher<ColorListResponse, Error> {
        networkService.request(ColorEndpoint.list(page: page))
    }

    func fetchColor(id: Int) -> AnyPublisher<ColorDetailResponse, Error> {
        networkService.request(ColorEndpoint.detail(id: id))
    }
}
