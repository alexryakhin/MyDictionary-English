//
//  GlassTabBar.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct GlassTabBar: View {
    var showsSearchBar: Bool = false
    @Binding var activeTab: TabBarItem
    var onSearchBarExpanded: (Bool) -> () = { _ in }
    var onSearchTextChanged: (String) -> () = { _ in }

    /// View Properties
    @GestureState private var isActive: Bool = false
    @State private var isInitialOffsetSet: Bool = false
    @State private var dragOffset: CGFloat = 0
    @State private var lastDragOffset: CGFloat?

    var body: some View {
        GeometryReader {
            let size = $0.size
            let tabs = TabBarItem.allCases.prefix(showsSearchBar ? 4 : 5)
            let tabItemWidth = max(min(size.width / CGFloat(tabs.count + (showsSearchBar ? 1 : 0)), 90), 60)
            let tabItemHeight: CGFloat = 56

            ZStack {
                if isInitialOffsetSet {
                    HStack(spacing: 0) {
                        ForEach(tabs, id: \.index) { tab in
                            TabItemView(
                                tab,
                                width: tabItemWidth,
                                height: tabItemHeight
                            )
                        }
                    }
                    /// Draggable Active Tab
                    .background(alignment: .leading) {
                        ZStack {
                            Capsule()
                                .stroke(.gray.opacity(0.25), lineWidth: 3)
                                .opacity(isActive ? 1 : 0)

                            Capsule()
                                .fill(.background)
                        }
                        .compositingGroup()
                        .frame(width: tabItemWidth, height: tabItemHeight)
                        /// Scaling when drag gesture becomes active
                        .scaleEffect(isActive ? 1.3 : 1)
                        .offset(x: dragOffset)
                    }
                    .padding(3)
                    .background(TabBarBackground())
                }
            }
            /// Centering Tab Bar
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .onAppear {
                guard !isInitialOffsetSet else { return }
                dragOffset = CGFloat(activeTab.index) * tabItemWidth
                isInitialOffsetSet = true
            }
        }
        .frame(height: 56)
        .padding(.horizontal, 16)
        /// Animations (Customize it as per your needs!)
        .animation(.bouncy, value: dragOffset)
        .animation(.bouncy, value: isActive)
        .animation(.smooth, value: activeTab)
    }

    /// Tab Item View
    @ViewBuilder
    private func TabItemView(_ tab: TabBarItem, width: CGFloat, height: CGFloat) -> some View {
        let tabs = TabBarItem.allCases.prefix(showsSearchBar ? 4 : 5)
        let tabCount = tabs.count - 1

        VStack(spacing: 4) {
            Image(systemName: activeTab == tab ? tab.selectedImage : tab.image)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)

            Text(tab.title)
                .font(.caption2)
                .lineLimit(1)
        }
        .foregroundStyle(activeTab == tab ? .accent : Color.secondary)
        .frame(width: width, height: height)
        .contentShape(.capsule)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .updating($isActive, body: { _, out, _ in
                    out = true
                })
                .onChanged({ value in
                    let xOffset = value.translation.width
                    if let lastDragOffset {
                        let newDragOffset = xOffset + lastDragOffset
                        dragOffset = max(min(newDragOffset, CGFloat(tabCount) * width), 0)
                    } else {
                        lastDragOffset = dragOffset
                    }
                })
                .onEnded({ value in
                    lastDragOffset = nil
                    /// Identifying the landing index
                    let landingIndex = Int((dragOffset / width).rounded())
                    /// Safe-Check
                    if tabs.indices.contains(landingIndex) {
                        dragOffset = CGFloat(landingIndex) * width
                        activeTab = tabs[landingIndex]
                    }
                })
        )
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    activeTab = tab
                    dragOffset = CGFloat(tab.index) * width
                }
        )
        .onChange(of: activeTab) {
            dragOffset = CGFloat(activeTab.index) * width
        }
    }

    /// Tab Bar Background View
    @ViewBuilder
    private func TabBarBackground() -> some View {
        ZStack {
            Capsule(style: .continuous)
                .stroke(.gray.opacity(0.25), lineWidth: 1.5)

            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
        }
        .compositingGroup()
    }
}

#Preview {
    @State var activeTab: TabBarItem = .myDictionary

    return VStack {
        Spacer()
        GlassTabBar(activeTab: $activeTab)
    }
    .background(Color.gray.opacity(0.1))
}
