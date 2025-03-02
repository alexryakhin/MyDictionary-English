//
//  ListWithDivider.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 9/12/24.
//

import SwiftUI

/// Has a built-in divider between each element, except the last element.
struct ListWithDivider<
    Data: RandomAccessCollection,
    Content: View
>: View {

    private let data: Data
    private let dividerLeadingPadding: CGFloat
    private let content: (Data.Element) -> Content

    init(
        _ data: Data,
        dividerLeadingPadding: CGFloat = 16,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.content = content
        self.dividerLeadingPadding = dividerLeadingPadding
    }

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                let lastIndex = data.count - 1
                VStack(spacing: 0) {
                    content(item)
                    if index != lastIndex {
                        Divider()
                            .padding(.leading, dividerLeadingPadding)
                    }
                }
            }
        }
    }
}
