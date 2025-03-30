//
//  PageViewController.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI
import AppKit
import class Combine.AnyCancellable

open class PageViewController<Content: PageView>: NSHostingController<Content> {

    public var cancellables: Set<AnyCancellable> = []

    override public init(rootView: Content) {
        super.init(rootView: rootView)
        setup()
    }

    open override func viewWillAppear() {
        super.viewWillAppear()
        setupNavigationBar()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func setupNavigationBar() {}

    open func setup() {}
}
