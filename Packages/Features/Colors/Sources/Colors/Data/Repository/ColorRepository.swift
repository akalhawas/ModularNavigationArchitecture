//
//  ColorRepository.swift
//  Colors
//
//  Created by ali alhawas on 24/07/2026.
//

import Combine

protocol ColorRepository {
    func fetchColors(page: Int) -> AnyPublisher<ColorListResponse, Error>
    func fetchColor(id: Int) -> AnyPublisher<ColorDetailResponse, Error>
}
