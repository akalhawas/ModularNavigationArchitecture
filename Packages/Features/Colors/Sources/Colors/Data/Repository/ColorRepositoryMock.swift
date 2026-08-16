//
//  ColorRepositoryMock.swift
//  Colors
//
//  Created by ali alhawas on 24/07/2026.
//

import Combine

final class ColorRepositoryMock: ColorRepository {

    func fetchColors(page: Int) -> AnyPublisher<ColorListResponse, Error> {
        let response = ColorListResponse(
            page: page,
            perPage: 6,
            total: 1,
            totalPages: 1,
            data: [Self.mockColor],
            support: Self.mockSupport
        )
        return Just(response).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func fetchColor(id: Int) -> AnyPublisher<ColorDetailResponse, Error> {
        let response = ColorDetailResponse(data: Self.mockColor, support: Self.mockSupport)
        return Just(response).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    private static let mockColor = AppColor(
        id: 1,
        name: "Mock AppColor",
        year: 2026,
        color: "#98B2D1",
        pantoneValue: "15-4020"
    )

    private static let mockSupport = SupportInfo(url: "https://reqres.in/#support-heading", text: "Mock data")
}
