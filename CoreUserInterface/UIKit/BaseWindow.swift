//
//  BaseWindow.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import UIKit

public final class BaseWindow: UIWindow {
    #if DEBUG
    public var onShakeDetected: (() -> Void)?
    #endif

    override public func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)

        #if DEBUG
        if motion == .motionShake {
            onShakeDetected?()
        }
        #endif
    }
}
