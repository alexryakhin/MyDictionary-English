//
//  TTSLanguage+Extension.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/23/25.
//

import SwiftUI

extension TTSLanguage {
    var title: LocalizedStringKey {
        switch self {
        case .en:
            return "British"
        case .enUS:
            return "American"
        }
    }
}
