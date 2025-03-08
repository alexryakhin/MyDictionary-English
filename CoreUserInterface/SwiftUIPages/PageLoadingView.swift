//
//  PageLoadingView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct PageLoadingView: View {

    private let props: DefaultLoaderProps

    public init(
        props: DefaultLoaderProps
    ) {
        self.props = props
    }

    var body: some View {
        ProgressView()
            .frame(width: 24, height: 24)
    }
}
