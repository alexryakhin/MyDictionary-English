//
//  ListWithCustomNavBar.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct ListWithCustomNavBar<Data: RandomAccessCollection, CellView: View, NavigationBar: View>: View where Data.Element: Identifiable {

    private let data: Data
    private let cellView: (Data.Element) -> CellView
    private let navigationBar: () -> NavigationBar

    @State private var scrollOffset: CGFloat = .zero
    @State private var navBarSize: CGSize = .zero
    private var navigationBarOpacity: CGFloat {
        min(max(-(scrollOffset-navBarSize.height-16) / 20, 0), 1)
    }

    init(
        _ data: Data,
        @ViewBuilder cellView: @escaping (Data.Element) -> CellView,
        @ViewBuilder navigationBar: @escaping () -> NavigationBar
    ) {
        self.data = data
        self.cellView = cellView
        self.navigationBar = navigationBar
    }

    var body: some View {
        List(data) { element in
            cellView(element)
                .if(data.first?.id == element.id, transform: { cell in
                    cell
                        .background(GeometryReader { geometry in
                            Color.clear.preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: geometry.frame(in: .named(ScrollOffsetPreferenceKey.coordinateSpaceName)).minY
                            )
                        })
                        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                            scrollOffset = value
                        }
                })
        }
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .top) {
            ChildSizeReader(size: $navBarSize) {
                navigationBar()
            }
            .background {
                VStack(spacing: 0) {
                    Color.clear.background(.thinMaterial)
                    Divider()
                }
                .opacity(navigationBarOpacity)
            }
            .padding(.bottom, -16)
        }
    }
}

// Preference key for tracking scroll position
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static let coordinateSpaceName = "scroll"
    static let defaultValue: CGFloat = .zero

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    }
}
