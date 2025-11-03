//
//  MusicLearningContentView.swift
//  My Dictionary
//
//  Created by AI Assistant
//

import SwiftUI

struct MusicLearningContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Music Learning")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Coming soon: Select songs from Apple Music or Spotify to learn languages through music!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    MusicLearningContentView()
}

