//
//  AddIdiomViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/20/25.
//

import Combine
import SwiftUI

final class AddIdiomViewModel: BaseViewModel {
    @Published var inputText: String = ""
    @Published var inputDefinition: String = ""

    private let idiomsManager: AddIdiomManagerInterface

    init(
        inputText: String
    ) {
        self.inputText = inputText
        self.idiomsManager = ServiceManager.shared.createAddIdiomManager()
    }

    func addIdiom() {
        do {
            try idiomsManager.addNewIdiom(inputText, definition: inputDefinition)
            AnalyticsService.shared.logEvent(.idiomAdded)
            dismissPublisher.send()
        } catch {
            errorReceived(error, displayType: .alert)
        }
    }
}
