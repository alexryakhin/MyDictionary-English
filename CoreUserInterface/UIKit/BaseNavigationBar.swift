//
//  BaseNavigationBar.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import UIKit

open class BaseNavigationBar: UINavigationBar {

    // MARK: - Init
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Methods to Implement
    
    open func setup() { }
}

public final class NavigationBar: BaseNavigationBar {}
