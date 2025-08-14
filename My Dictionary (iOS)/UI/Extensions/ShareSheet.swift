//
//  ShareSheet.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/26/25.
//

import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    init(activityItems: [Any]) {
        self.activityItems = activityItems
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
