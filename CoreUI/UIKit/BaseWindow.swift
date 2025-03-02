//
//  BaseWindow.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 10/9/24.
//

import UIKit

final class BaseWindow: UIWindow {
    #if DEBUG
    var onShakeDetected: (() -> Void)?
    #endif

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)

        #if DEBUG
        if motion == .motionShake {
            onShakeDetected?()
        }
        #endif
    }
}
