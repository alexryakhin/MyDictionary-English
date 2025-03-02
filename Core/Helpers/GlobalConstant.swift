//
//  GlobalConstant.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/22/25.
//

import SwiftUI

enum GlobalConstant {

    static var appVersion: String? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }

    static var buildVersion: String? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
    }

    static var currentFullAppVersion: String {
        String(appVersion ?? "-", buildVersion ?? "–", separator: ".")
    }

    static var wordnikApiKey: String {
        "MY_API_KEY"
    }

    static var buyMeACoffeeUrl: URL {
        URL(string: "https://buymeacoffee.com/xander1100001")!
    }
}
