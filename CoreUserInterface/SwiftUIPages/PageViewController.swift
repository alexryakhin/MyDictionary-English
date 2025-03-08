//
//  PageViewController.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI
import UIKit
import class Combine.AnyCancellable

open class PageViewController<Content: PageView>: UIHostingController<Content> {

    public var onSearchSubmit: ((String) -> Void)?
    public var onSearchCancel: (() -> Void)?
    public var onSearchEnded: (() -> Void)?

    public var cancellables: Set<AnyCancellable> = []

    override public init(rootView: Content) {
        super.init(rootView: rootView)
        setup()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar(animated: animated)
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupNavigationBar(animated: animated)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func setupNavigationBar(animated: Bool) { }

    open func setup() {
        view.backgroundColor = .systemBackground
    }

    public final func setupSearchBar(placeholder: String = "Search recipes") {
        // Initialize the search controller
        let searchController = BaseSearchController()
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = placeholder
        searchController.onSearchCancel = onSearchCancel
        searchController.onSearchSubmit = onSearchSubmit
        searchController.onSearchEnded = onSearchEnded
        // Add the search bar to the navigation item
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        // Ensure the search bar is always visible
        definesPresentationContext = true
    }

    public final func setupTransparentNavBar() {
        let appearance = UINavigationBarAppearance()

        // Configure the appearance with a transparent background
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear // Set to clear to ensure full transparency

        // Apply the appearance to the navigation bar
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance

        // If you have a compact appearance, apply it as well
        navigationController?.navigationBar.compactAppearance = appearance
    }

    public final func resetNavBarAppearance() {
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithDefaultBackground()
        let scrollEdgeAppearance = UINavigationBarAppearance()
        scrollEdgeAppearance.configureWithTransparentBackground()
        // Apply the appearance to the navigation bar
        navigationController?.navigationBar.standardAppearance = standardAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = scrollEdgeAppearance
    }
}
