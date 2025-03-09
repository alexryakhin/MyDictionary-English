//
//  BaseSearchController.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import UIKit

final public class BaseSearchController: UISearchController, UISearchBarDelegate, UISearchControllerDelegate {

    public var onSearchSubmit: ((String) -> Void)?
    public var onSearchCancel: (() -> Void)?
    public var onSearchEnded: (() -> Void)?

    override init(searchResultsController: UIViewController? = nil) {
        super.init(searchResultsController: searchResultsController)
        customizeSearchBar()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        customizeSearchBar()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    private func customizeSearchBar() {
        searchBar.delegate = self
        delegate = self
        let searchTextField = searchBar.searchTextField
        searchTextField.layer.cornerRadius = 18
        searchTextField.layer.masksToBounds = true
    }

    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        onSearchCancel?()
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let text = searchBar.text {
            onSearchSubmit?(text)
        }
    }

    public func didDismissSearchController(_ searchController: UISearchController) {
        onSearchEnded?()
    }

    private func resetNavBarAppearance() {
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithDefaultBackground()
        let scrollEdgeAppearance = UINavigationBarAppearance()
        scrollEdgeAppearance.configureWithTransparentBackground()
        // Apply the appearance to the navigation bar
        navigationController?.navigationBar.standardAppearance = standardAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = scrollEdgeAppearance
    }
}
