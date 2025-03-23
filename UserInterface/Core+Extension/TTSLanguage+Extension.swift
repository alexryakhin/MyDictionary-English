//
//  TTSLanguage+Extension.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/23/25.
//

import Core
import SwiftUI

extension TTSLanguage {
    public var title: LocalizedStringKey {
        switch self {
        case .en:
            return "British"
        case .enUS:
            return "American"
        }
    }
}
