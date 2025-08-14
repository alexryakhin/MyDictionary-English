//
//  ColorSelectionButton.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/15/25.
//

import SwiftUI

struct ColorSelectionButton: View {
    let color: TagColor
    let isSelected: Bool
    let action: VoidHandler
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color.color)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 3)
                )
                .overlay(
                    Image(systemName: "checkmark")
                        .foregroundStyle(.white)
                        .font(.caption)
                        .fontWeight(.bold)
                        .opacity(isSelected ? 1 : 0)
                )
        }
        .buttonStyle(.plain)
    }
}
