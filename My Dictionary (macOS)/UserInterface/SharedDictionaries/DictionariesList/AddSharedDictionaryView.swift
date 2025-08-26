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
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollViewWithCustomNavBar {
            VStack(spacing: 16) {
                CustomSectionView(header: Loc.SharedDictionaries.name) {
                    TextField(Loc.SharedDictionaries.enterDictionaryName, text: $name)
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
            NavigationBarView(title: Loc.SharedDictionaries.newSharedDictionary)
        }
        .safeAreaInset(edge: .bottom) {
            AsyncActionButton(Loc.SharedDictionaries.createSharedDictionary) {
                try await createDictionary()
            }
            .padding(vertical: 12, horizontal: 16)
            .disabled(name.isEmpty)
        }
        .groupedBackground()
    }
    
    private func createDictionary() async throws {
        guard !name.isEmpty else {
            showAlertWithMessage(Loc.SharedDictionaries.dictionaryNameRequired)
            return
        }
        
        guard let userId = authenticationService.userId else {
            showAlertWithMessage(Loc.SharedDictionaries.signInToCreateSharedDictionary)
            return
        }
        try await dictionaryService.createSharedDictionary(
            userId: userId,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        dismiss()
    }
}
