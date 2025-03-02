//
//  DeviceInfoManager.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 9/29/24.
//

import Foundation
import UIKit.UIDevice

protocol DeviceInfoManagerInterface: AnyObject {

    func gatherInfo() async -> DeviceInfo
}

final class DeviceInfoManager: DeviceInfoManagerInterface {

    init() {}

    func gatherInfo() -> DeviceInfo {
        let locale = Locale.current
        let calendar = Calendar.current
        let device = UIDevice.current

        let languageCode: String
        if #available(iOS 16, *) {
            languageCode = locale.language.languageCode?.identifier ?? "en"
        } else {
            languageCode = locale.languageCode ?? "en"
        }
        return DeviceInfo(
            languageCode: languageCode,
            timezoneIdentifier: calendar.timeZone.identifier,
            currentFullAppVersion: currentFullAppVersion(),
            identifierForVendor: device.identifierForVendor?.uuidString ?? "",
            deviceModel: device.model,
            systemName: device.systemName,
            systemVersion: device.systemVersion
        )
    }

    private func currentFullAppVersion() -> String {
        String(GlobalConstant.appVersion ?? "-", GlobalConstant.buildVersion ?? "–", separator: ".")
    }
}
