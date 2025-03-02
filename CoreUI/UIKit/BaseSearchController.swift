//
//  BaseSearchController.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 9/21/24.
//

import UIKit

final class BaseSearchController: UISearchController, UISearchBarDelegate, UISearchControllerDelegate {

    var onSearchSubmit: ((String) -> Void)?
    var onSearchCancel: (() -> Void)?
    var onSearchEnded: (() -> Void)?

    override init(searchResultsController: UIViewController? = nil) {
        super.init(searchResultsController: searchResultsController)
        customizeSearchBar()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        customizeSearchBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resetNavBarAppearance()
    }

    private func customizeSearchBar() {
        searchBar.delegate = self
        delegate = self
        let searchTextField = searchBar.searchTextField
        searchTextField.layer.cornerRadius = 18
        searchTextField.layer.masksToBounds = true
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        onSearchCancel?()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let text = searchBar.text {
            onSearchSubmit?(text)
        }
    }

    func didDismissSearchController(_ searchController: UISearchController) {
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
