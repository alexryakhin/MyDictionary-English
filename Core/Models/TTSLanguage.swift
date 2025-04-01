//
//  TTSLanguage.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/23/25.
//

public enum TTSLanguage: String, CaseIterable, Identifiable, Hashable {
    case en
    case enUS = "en-us"

    public var id: String {
        rawValue
    }
}
