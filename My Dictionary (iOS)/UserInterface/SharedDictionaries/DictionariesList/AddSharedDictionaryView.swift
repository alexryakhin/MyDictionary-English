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
        ScrollView {
            VStack(spacing: 16) {
                CustomSectionView(header: Loc.SharedDictionaries.name.localized) {
                    TextField(Loc.SharedDictionaries.enterDictionaryName.localized, text: $name)
                        .submitLabel(.done)
                        .textContentType(.organizationName)
                        .padding(vertical: 8, horizontal: 12)
                        .background(Color.tertiarySystemGroupedBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 16)
            .if(isPad) { view in
                view
                    .frame(maxWidth: 550, alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .safeAreaInset(edge: .bottom) {
            AsyncActionButton(Loc.SharedDictionaries.createSharedDictionary.localized) {
                try await createDictionary()
            }
            .padding(vertical: 12, horizontal: 16)
        }
        .groupedBackground()
        .navigation(
            title: Loc.SharedDictionaries.newSharedDictionary.localized,
            mode: .inline,
            trailingContent: {
                HeaderButton(icon: "xmark") {
                    dismiss()
                }
            }
        )
        .presentationDetents([.medium])
    }
    
    private func createDictionary() async throws {
        guard !name.isEmpty else {
            showAlertWithMessage(Loc.SharedDictionaries.dictionaryNameRequired.localized)
            return
        }
        
        guard let userId = authenticationService.userId else {
            showAlertWithMessage(Loc.SharedDictionaries.signInToCreateSharedDictionary.localized)
            return
        }
        try await dictionaryService.createSharedDictionary(
            userId: userId,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        dismiss()
    }
}
