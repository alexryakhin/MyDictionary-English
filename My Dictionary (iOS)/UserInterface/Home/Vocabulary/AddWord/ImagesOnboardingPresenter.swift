//
//  ImagesOnboardingPresenter.swift
//  My Dictionary
//
//  Created by AI Assistant on 1/9/25.
//

import SwiftUI

struct ImagesOnboardingPresenter: ViewModifier {
    @Binding var isPresented: Bool
    let onCompleted: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                ImagesOnboardingView(isPresented: $isPresented, onCompleted: onCompleted)
            }
    }
}

extension View {
    func imagesOnboarding(isPresented: Binding<Bool>, onCompleted: (() -> Void)? = nil) -> some View {
        modifier(ImagesOnboardingPresenter(isPresented: isPresented, onCompleted: onCompleted))
    }
}
