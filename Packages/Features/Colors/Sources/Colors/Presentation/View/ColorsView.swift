//
//  ColorsView.swift
//  Colors
//
//  Created by ali alhawas on 24/07/2026.
//

import SwiftUI
import Navigation

struct ColorsView: View {

    @StateObject private var viewModel: ColorsViewModel
    @EnvironmentObject var coordinator: NavigationCoordinator

    init(viewModel: ColorsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack {
            content
                .navigationTitle("Colors")
                .task {
                    if viewModel.colors.isEmpty {
                        viewModel.fetchColors()
                    }
                }

            Button {
                viewModel.crossFeatureDelegate?.onPrimaryAction(coordinator: coordinator, id: 2) {
                    viewModel.didReturnFromTertiaryAction()
                }
            } label: {
                Text("Users")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let errorMessage = viewModel.errorMessage {
            ErrorStateView(message: errorMessage) {
                viewModel.fetchColors()
            }
        } else if viewModel.colors.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(viewModel.colors) { color in
                Button {
//                    coordinator.navigate(to: ColorsRoute.colorDetail(id: color.id))
                    coordinator.presentSheet(ColorsRoute.colorDetail(id: color.id))
                } label: {
                    ColorRow(color: color)
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .refreshable {
                viewModel.fetchColors()
            }
        }
    }
}

private struct ColorRow: View {

    let color: AppColor

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: color.color))
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(color.name.capitalized)
                    .font(.headline)
                Text("\(color.year)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

extension Color {
    init(hex: String) {
        var hexValue = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexValue.removeAll { $0 == "#" }

        var rgb: UInt64 = 0
        Scanner(string: hexValue).scanHexInt64(&rgb)

        let red = Double((rgb & 0xFF0000) >> 16) / 255
        let green = Double((rgb & 0x00FF00) >> 8) / 255
        let blue = Double(rgb & 0x0000FF) / 255

        self.init(red: red, green: green, blue: blue)
    }
}

private final class PreviewColorsCrossFeatureDelegate: ColorsCrossFeatureDelegate {
    func onPrimaryAction(coordinator: NavigationCoordinator, id: Int, onReturn: @escaping () -> Void) {}
    func onSecondaryAction(coordinator: NavigationCoordinator, id: Int, onReturn: @escaping () -> Void) {}
}

#Preview {
    NavigationStack {
        ColorsView(
            viewModel: ColorsViewModel(
                fetchColorsUseCase: FetchColorsUseCaseImp(repository: ColorRepositoryMock()),
                crossFeatureDelegate: PreviewColorsCrossFeatureDelegate()
            )
        )
    }
}
