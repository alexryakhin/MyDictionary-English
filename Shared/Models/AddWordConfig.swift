//
//  AddWordConfig.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 11/9/25.
//

import Foundation

struct AddWordConfig: Hashable {
    let input: String?
    let inputLanguage: InputLanguage?
    let selectedDictionaryId: String?
    let isWord: Bool

    init(
        input: String?,
        inputLanguage: InputLanguage?,
        selectedDictionaryId: String?,
        isWord: Bool
    ) {
        self.input = input
        self.inputLanguage = inputLanguage
        self.selectedDictionaryId = selectedDictionaryId
        self.isWord = isWord
    }
}
