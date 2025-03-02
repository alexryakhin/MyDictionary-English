//
//  ServiceLayer.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 10/2/24.
//

import Foundation
import UIKit

final class ServiceLayer {

    var environment: AppEnvironment

    let persistent: Persistent

    // MARK: - HostInfoProviderInterface properties

    init(
        persistent: Persistent,
        deviceInfoManager: DeviceInfoManagerInterface
    ) {
        self.persistent = persistent
        environment = persistent.environment
    }

    func set(environment: AppEnvironment) {
        self.environment = environment
        persistent.set(.environment(environment))
    }
}
