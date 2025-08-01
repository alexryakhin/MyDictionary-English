//
//  DeviceHelper.swift
//  Flippin
//
//  Created by Alexander Riakhin on 7/11/25.
//
import UIKit

var isPad: Bool {
    UIDevice.current.userInterfaceIdiom == .pad
}

func iPadSpecific(_ closure: () -> Void) {
    if isPad {
        closure()
    }
}
