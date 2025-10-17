//
//  OnboardingNativeLanguageView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 10/17/25.
//

import SwiftUI

extension OnboardingFlow {
    struct NativeLanguageView: View {
        @ObservedObject var viewModel: OnboardingFlow.ViewModel
        @State private var searchText = ""
        @State private var animateContent = false
        @State private var showList = false

        var filteredLanguages: [InputLanguage] {
            if searchText.isEmpty {
                return InputLanguage.allCases
            }
            return InputLanguage.allCases.filter {
                $0.displayName.lowercased().contains(searchText.lowercased())
            }
        }

        var body: some View {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Spacer()
                            .frame(height: 40)
                        
                        // Animated icon
                        ZStack {
                            Circle()
                                .fill(Color.indigo.opacity(0.1))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "flag.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(Color.indigo)
                                .scaleEffect(animateContent ? 1.0 : 0.5)
                        }
                        .animation(.spring(response: 1.0, dampingFraction: 0.8), value: animateContent)
                        
                        Text(Loc.Onboarding.whatsYourNativeLanguage)
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .multilineTextAlignment(.center)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                            .animation(.easeInOut(duration: 0.8).delay(0.2), value: animateContent)
                            .padding(.horizontal, 16)
                        
                        InputView.searchView(Loc.Onboarding.searchYourLanguage, searchText: $searchText)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                            .animation(.easeInOut(duration: 0.8).delay(0.4), value: animateContent)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(Array(filteredLanguages.enumerated()), id: \.element) { index, language in
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        viewModel.nativeLanguage = language
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        viewModel.navigate(to: .interests)
                                    }
                                }) {
                                    HStack {
                                        Text(language.displayName)
                                        Spacer()
                                        if viewModel.nativeLanguage == language {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.accentColor)
                                                .transition(.scale.combined(with: .opacity))
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(viewModel.nativeLanguage == language
                                                  ? Color.accentColor.opacity(0.1)
                                                  : Color.systemBackground)
                                            .shadow(color: .label.opacity(0.03), radius: 4, x: 0, y: 2)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .opacity(showList ? 1 : 0)
                                .offset(y: showList ? 0 : 20)
                                .animation(.easeInOut(duration: 0.4).delay(0.5 + Double(min(index, 5)) * 0.05), value: showList)
                            }
                        }
                    }
                    .padding(vertical: 12, horizontal: 16)
                }
            }
            .onAppear {
                withAnimation {
                    animateContent = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showList = true
                }
            }
        }
        
        private var backgroundGradient: some View {
            LinearGradient(
                colors: [
                    Color.indigo.opacity(0.08),
                    Color.purple.opacity(0.05),
                    Color.systemBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
