//
//  DefaultPlaceholderProps.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

public struct DefaultPlaceholderProps: Equatable {

    let title: String?
    let subtitle: String?

    public init(
        title: String? = nil,
        subtitle: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
    }
}
