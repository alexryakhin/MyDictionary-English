//
//  AddSharedDictionaryView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct AddSharedDictionaryView: View {
    @StateObject var dictionaryService: DictionaryService = .shared
    @StateObject var authenticationService: AuthenticationService = .shared
    @State private var name = ""
    @State private var isLoading: Bool = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollViewWithCustomNavBar {
            VStack(spacing: 16) {
                CustomSectionView(header: Loc.name.localized) {
                    TextField(Loc.enterDictionaryName.localized, text: $name)
                        .textFieldStyle(.plain)
                        .submitLabel(.done)
                        .textContentType(.organizationName)
                        .padding(vertical: 8, horizontal: 12)
                        .background(Color.tertiarySystemGroupedBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(16)
        } navigationBar: {
            NavigationBarView(title: Loc.newSharedDictionary.localized)
        }
        .safeAreaInset(edge: .bottom) {
            ActionButton(Loc.createSharedDictionary.localized, isLoading: isLoading) {
                createDictionary()
            }
            .padding(vertical: 12, horizontal: 16)
            .disabled(name.isEmpty)
        }
        .groupedBackground()
    }
    
    private func createDictionary() {
        guard !name.isEmpty else {
            showAlertWithMessage(Loc.dictionaryNameRequired.localized)
            return
        }
        
        guard let userId = authenticationService.userId else {
            showAlertWithMessage(Loc.signInToCreateSharedDictionary.localized)
            return
        }
        Task { @MainActor in
            isLoading = true
            defer { isLoading = false }
            do {
                try await dictionaryService.createSharedDictionary(
                    userId: userId,
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                dismiss()
            } catch {
                errorReceived(error)
            }
        }
    }
}
