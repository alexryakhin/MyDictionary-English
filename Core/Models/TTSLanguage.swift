//
//  TTSLanguage.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/23/25.
//

enum TTSLanguage: String, CaseIterable, Identifiable, Hashable {
    case en
    case enUS = "en-us"

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .en:
            return "British"
        case .enUS:
            return "American"
        }
    }
}
