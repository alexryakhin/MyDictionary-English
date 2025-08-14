//
//  DeviceHelper.swift
//  Flippin
//
//  Created by Alexander Riakhin on 7/11/25.
//
#if os(iOS)
import UIKit
#endif

var isPad: Bool {
    #if os(iOS)
    UIDevice.current.userInterfaceIdiom == .pad
    #else
    false
    #endif
}

func iPadSpecific(_ closure: VoidHandler) {
    #if os(iOS)
    if isPad {
        closure()
    }
    #endif
}
