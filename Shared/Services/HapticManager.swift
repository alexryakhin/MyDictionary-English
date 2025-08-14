//
//  HapticManager.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

#if os(iOS)
import UIKit
#endif

struct HapticManager {

    enum ImpactStyle {
        case light
        case medium
        case heavy
        case soft
        case rigid

        #if os(iOS)
        var systemStyle: UIImpactFeedbackGenerator.FeedbackStyle {
            switch self {
            case .light: .light
            case .medium: .medium
            case .heavy: .heavy
            case .soft: .soft
            case .rigid: .rigid
            }
        }
        #endif
    }

    enum FeedbackType {
        case success
        case warning
        case error

        #if os(iOS)
        var systemType: UINotificationFeedbackGenerator.FeedbackType {
            switch self {
            case .success: .success
            case .warning: .warning
            case .error: .error
            }
        }
        #endif
    }

    static let shared = HapticManager()
    
    private init() {}

    func triggerImpact(style: ImpactStyle) {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: style.systemStyle)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }

    func triggerNotification(type: FeedbackType) {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type.systemType)
        #endif
    }

    func triggerSelection() {
        #if os(iOS)
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
        #endif
    }
}
