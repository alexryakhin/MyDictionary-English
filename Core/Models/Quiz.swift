//
//  Quiz.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

public enum Quiz: String, CaseIterable, Identifiable {
    case spelling
    case chooseDefinitions

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .spelling:
            return "Spelling"
        case .chooseDefinitions:
            return "Choose definitions"
        }
    }
}
