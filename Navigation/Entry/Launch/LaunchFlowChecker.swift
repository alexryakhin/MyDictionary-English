//
//  LaunchFlowChecker.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 10/2/24.
//
import Combine

enum Flow {
    case home
}

protocol LaunchFlowCheckerInterface: AnyObject {

#if DEBUG
    var overriddenFlow: Flow? { get set }
#endif
    func flowToLaunch() -> Flow
}

final class LaunchFlowChecker: LaunchFlowCheckerInterface {

#if DEBUG
    var developerHomeShownAlready = false
    var overriddenFlow: Flow?
#endif

    init() {}

    func flowToLaunch() -> Flow {
        return .home
    }
}
