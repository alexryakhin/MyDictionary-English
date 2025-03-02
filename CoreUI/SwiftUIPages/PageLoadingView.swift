//
//  PageLoadingView.swift
//  Suint One
//
//  Created by Aleksandr Riakhin on 9/30/24.
//

import SwiftUI

struct PageLoadingView: View {

    private let props: DefaultLoaderProps

    init(
        props: DefaultLoaderProps
    ) {
        self.props = props
    }

    var body: some View {
        ProgressView()
            .frame(width: 24, height: 24)
    }
}
