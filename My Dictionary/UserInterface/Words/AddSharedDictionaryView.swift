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
                CustomSectionView(header: "Name") {
                    TextField("Enter dictionary name", text: $name)
                        .submitLabel(.done)
                        .textContentType(.organizationName)
                        .padding(vertical: 8, horizontal: 12)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 16)
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                createDictionary()
            } label: {
                Text("Create Shared Dictionary")
                    .font(.headline)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
            }
            .disabled(name.isEmpty)
            .buttonStyle(.borderedProminent)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(vertical: 12, horizontal: 16)
        }
        .groupedBackground()
        .navigation(
            title: "New Shared Dictionary",
            mode: .inline,
            trailingContent: {
                HeaderButton(icon: "xmark") {
                    dismiss()
                }
            }
        )
        .presentationDetents([.medium])
    }
    
    private func createDictionary() {
        guard !name.isEmpty else {
            showAlertWithMessage("Dictionary name is required")
            return
        }
        
        guard let userId = authenticationService.userId else {
            showAlertWithMessage("Please sign in to create a shared dictionary")
            return
        }
        Task {
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
