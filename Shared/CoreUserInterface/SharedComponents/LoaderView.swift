//
//  LoaderView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/24/25.
//

import SwiftUI

struct LoaderView: View {
    @State private var isAnimating = false

    private let color: Color

    init(color: Color = .accent) {
        self.color = color
    }

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.8) // Example: a partial circle
            .stroke(color, lineWidth: 2)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}
