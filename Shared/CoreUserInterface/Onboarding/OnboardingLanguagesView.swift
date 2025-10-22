//
//  OnboardingLanguagesView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI
import Flow

extension OnboardingFlow {
    struct LanguagesView: View {
        @ObservedObject var viewModel: OnboardingFlow.ViewModel
        @State private var searchText = ""
        @State private var selectedLanguage: InputLanguage?
        @State private var selectedLevel: CEFRLevel = .b1
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
            ScrollView {
                VStack(spacing: 24) {
                    // Animated illustration
                    Image(.illustrationPlanet)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 220)
                        .scaleEffect(animateContent ? 1.0 : 0.5)
                        .animation(.spring(response: 1.0, dampingFraction: 0.8), value: animateContent)

                    // Title
                    Text(Loc.Onboarding.whichLanguagesToLearn)
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .multilineTextAlignment(.center)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                        .animation(.easeInOut(duration: 0.8).delay(0.2), value: animateContent)
                        .padding(.horizontal, 32)

                    // Content - Selected languages
                    if !viewModel.studyLanguages.isEmpty {
                        HFlow(alignment: .top, spacing: 12) {
                            ForEach(viewModel.studyLanguages) { studyLang in
                                HStack(spacing: 8) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(studyLang.language.displayName)
                                            .font(.subheadline.bold())
                                        Text(studyLang.proficiencyLevel.rawValue)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Button(action: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            viewModel.removeStudyLanguage(id: studyLang.id)
                                        }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.accentColor.opacity(0.15))
                                .cornerRadius(20)
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Search bar
                    InputView.searchView(Loc.Onboarding.searchLanguages, searchText: $searchText)
                        .padding(.horizontal, 24)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                        .animation(.easeInOut(duration: 0.8).delay(0.4), value: animateContent)

                    // Language list
                    LazyVStack(spacing: 8) {
                        ForEach(Array(filteredLanguages.enumerated()), id: \.element) { index, language in
                            if !viewModel.studyLanguages.contains(where: { $0.language == language }) {
                                Button(action: {
                                    selectedLanguage = language
                                }) {
                                    HStack {
                                        Text(language.displayName)
                                            .font(.body)
                                        Spacer()
                                        Image(systemName: "plus.circle")
                                            .foregroundColor(.accentColor)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.secondarySystemGroupedBackground)
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
                    .padding(.horizontal, 16)
                }
                .frame(maxWidth: .infinity)
                .padding(vertical: 12, horizontal: 16)
            }
            .withGradientBackground()
            .safeAreaBarIfAvailable {
                ActionButton(Loc.Onboarding.continue, style: .borderedProminent) {
                    viewModel.navigate(to: .interests)
                }
                .disabled(viewModel.studyLanguages.isEmpty)
                .padding(vertical: 12, horizontal: 16)
            }
            .sheet(item: $selectedLanguage) { language in
                LanguageLevelPicker(
                    language: language,
                    selectedLevel: $selectedLevel,
                    onSave: {
                        viewModel.addStudyLanguage(language: language, level: selectedLevel)
                        selectedLanguage = nil
                    }
                )
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
    }
}
