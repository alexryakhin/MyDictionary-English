//
//  BaseTabController.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import UIKit

open class BaseTabController: UITabBarController {

    public required init() {
        super.init(nibName: nil, bundle: nil)
        setup()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        navigationItem.backButtonTitle = ""
    }

    open func setup() {}
}

public final class TabController: BaseTabController {
    // MARK: - Public Properties

    public var controllers = [NavigationController]() {
        didSet {
            viewControllers = controllers
            selectedIndex = 0
        }
    }

    // MARK: - Public Methods

    public func forceSwitchTab(to tabIndex: Int) {
        selectedIndex = tabIndex
    }
}
