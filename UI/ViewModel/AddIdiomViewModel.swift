//
//  AddIdiomViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/20/25.
//

import Combine
import SwiftUI

final class AddIdiomViewModel: DefaultPageViewModel {
    @Published var inputText: String = ""
    @Published var inputDefinition: String = ""
    @Published var isShowingAlert = false

    private let idiomsManager: IdiomsManagerInterface

    init(
        inputText: String,
        idiomsManager: IdiomsManagerInterface
    ) {
        self.inputText = inputText
        self.idiomsManager = idiomsManager
    }

    func addIdiom() {
        if !inputText.isEmpty, !inputDefinition.isEmpty {
            idiomsManager.addNewIdiom(inputText, definition: inputDefinition)
            saveContext()
        } else {
            isShowingAlert = true
        }
    }

    private func saveContext() {
        do {
            try idiomsManager.saveContext()
        } catch {
            errorReceived(error, displayType: .snack)
        }
    }
}
