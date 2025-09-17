//
//  GlassTabBar.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct GlassTabBar: View {
    @Binding var activeTab: TabBarItem

    /// View Properties
    @GestureState private var isActive: Bool = false
    @State private var isInitialOffsetSet: Bool = false
    @State private var dragOffset: CGFloat = 0
    @State private var lastDragOffset: CGFloat?
    private let tabs = TabBarItem.allCases

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let tabItemWidth = max(min((size.width - 6) / CGFloat(tabs.count), 90), 60)
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
                        if isGlassAvailable {
                            Capsule()
                                .fill(Color.clear)
                                .frame(width: tabItemWidth, height: tabItemHeight)
                                .glassEffectIfAvailable(.regular, in: Capsule())
                                .scaleEffect(isActive ? 1.3 : 1)
                                .offset(x: dragOffset)
                        } else {
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
                    }
                }
            }
            .onAppear {
                guard !isInitialOffsetSet else { return }
                dragOffset = CGFloat(activeTab.index) * tabItemWidth
                isInitialOffsetSet = true
            }
            .padding(3)
            .background(TabBarBackground())
            .scaleEffect(isActive ? 1.02 : 1)
            /// Centering Tab Bar
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: 56)
        .padding(.horizontal, 12)
        /// Animations (Customize it as per your needs!)
        .animation(.bouncy, value: dragOffset)
        .animation(.bouncy, value: isActive)
        .animation(.smooth, value: activeTab)
    }

    /// Tab Item View
    @ViewBuilder
    private func TabItemView(_ tab: TabBarItem, width: CGFloat, height: CGFloat) -> some View {
        let tabCount = tabs.count - 1

        VStack(spacing: 4) {
            Image(systemName: activeTab == tab ? tab.selectedImage : tab.image)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)

            Text(tab.title)
                .font(.system(size: 10.4, weight: .medium, design: .rounded))
                .lineLimit(1)
        }
        .foregroundStyle(activeTab == tab ? .accent : Color.label)
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
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onChanged { _ in
                    dragOffset = CGFloat(tab.index) * width
                    lastDragOffset = dragOffset
                }
        )
        .onChange(of: activeTab) {
            dragOffset = CGFloat(activeTab.index) * width
        }
    }

    /// Tab Bar Background View
    @ViewBuilder
    private func TabBarBackground() -> some View {
        if isGlassAvailable {
            Capsule()
                .fill(Color.clear)
                .glassEffectIfAvailable(.regular, in: .capsule)
        } else {
            ZStack {
                Capsule()
                    .stroke(.gray.opacity(0.25), lineWidth: 1.5)

                Capsule()
                    .fill(.ultraThinMaterial)
            }
            .compositingGroup()
        }
    }
}

#Preview {
    @Previewable @State var activeTab: TabBarItem = .myDictionary

    return VStack {
        Spacer()
        GlassTabBar(activeTab: $activeTab)
    }
    .background(Color.systemGroupedBackground)
}
