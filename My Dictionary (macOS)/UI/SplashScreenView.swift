//
//  SplashScreenView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/15/25.
//

import SwiftUI

struct SplashScreenView: View {
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 24) {
            // App icon
            Image(systemName: "textformat.abc")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
            
            // App name
            Text("My Dictionary")
                .font(.largeTitle)
                .bold()
            
            // Loading indicator
            ProgressView()
                .scaleEffect(1.2)
            
            // Loading text
            Text("Loading...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.systemGroupedBackground)
        .onAppear {
            isAnimating = true
        }
    }
}
