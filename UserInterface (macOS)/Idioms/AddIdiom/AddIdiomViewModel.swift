//
//  AddIdiomViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/20/25.
//

import Combine
import SwiftUI
import Services
import CoreUserInterface__macOS_
import Shared

final class AddIdiomViewModel: DefaultPageViewModel {
    @Published var inputText: String = ""
    @Published var inputDefinition: String = ""

    private let idiomsManager: AddIdiomManagerInterface

    init(
        inputText: String
    ) {
        self.inputText = inputText
        self.idiomsManager = DIContainer.shared.resolver.resolve(AddIdiomManagerInterface.self)!
    }

    func addIdiom() {
        do {
            try idiomsManager.addNewIdiom(inputText, definition: inputDefinition)
        } catch {
            errorReceived(error, displayType: .alert)
        }
    }
}
