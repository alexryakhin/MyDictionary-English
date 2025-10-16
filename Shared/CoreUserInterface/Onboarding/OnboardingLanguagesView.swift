//
//  OnboardingLanguagesView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct OnboardingLanguagesView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var searchText = ""
    @State private var selectedLanguage: InputLanguage?
    @State private var selectedLevel: CEFRLevel = .b1
    
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
                Spacer()
                    .frame(height: 40)
                
                // Image
                Image(systemName: "globe")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.accentColor)
                
                // Title
                Text(Loc.Onboarding.whichLanguagesToLearn)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            
                // Content - Selected languages
                if !viewModel.studyLanguages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
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
                                        viewModel.removeStudyLanguage(id: studyLang.id)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.accentColor.opacity(0.1))
                                .cornerRadius(20)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                
                // Search bar
                SearchBar(text: $searchText, placeholder: Loc.Onboarding.searchLanguages)
                    .padding(.horizontal, 24)
                
                // Language list
                LazyVStack(spacing: 8) {
                    ForEach(filteredLanguages, id: \.self) { language in
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
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                    .frame(height: 40)
            }
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            ActionButton(Loc.Onboarding.continue) {
                viewModel.navigate(to: .nativeLanguage)
            }
            .disabled(viewModel.studyLanguages.isEmpty)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
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
    }
}

// MARK: - Helper Views

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $text)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct LanguageLevelPicker: View {
    let language: InputLanguage
    @Binding var selectedLevel: CEFRLevel
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text(language.displayName)
                    .font(.title.bold())
                    .padding(.top, 32)
                
                Text(Loc.Onboarding.selectProficiencyLevel)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(CEFRLevel.allCases, id: \.self) { level in
                            Button(action: { selectedLevel = level }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(level.rawValue)
                                            .font(.headline)
                                        Spacer()
                                        if selectedLevel == level {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.accentColor)
                                        }
                                    }
                                    Text(level.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedLevel == level
                                              ? Color.accentColor.opacity(0.1)
                                              : Color.gray.opacity(0.05))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedLevel == level
                                                ? Color.accentColor
                                                : Color.clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                ActionButton(
                    Loc.Actions.add,
                    action: onSave
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(Loc.Actions.cancel) {
                        dismiss()
                    }
                }
            }
        }
    }
}

