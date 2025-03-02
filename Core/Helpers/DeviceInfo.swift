//
//  DeviceInfo.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 9/29/24.
//

import Foundation

struct DeviceInfo {
    /// Example: en
    let languageCode: String
    /// Example: America/Los_Angeles
    let timezoneIdentifier: String
    /// Bundle version and build number
    let currentFullAppVersion: String
    let identifierForVendor: String
    let deviceModel: String
    let systemName: String
    let systemVersion: String
}
