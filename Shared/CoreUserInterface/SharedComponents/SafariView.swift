//
//  SafariView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 10/23/25.
//

#if os(iOS)
import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        
        let controller = SFSafariViewController(url: url, configuration: config)
        controller.preferredControlTintColor = UIColor(Color.accentColor)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
}

extension View {
    /**
     Opens a URL in an in-app Safari browser.
     
     - Parameter url: Binding to the URL to open. Set to nil to dismiss.
     */
    func safari(url: Binding<URL?>) -> some View {
        sheet(isPresented: Binding(
            get: { url.wrappedValue != nil },
            set: { if !$0 { url.wrappedValue = nil } }
        )) {
            if let actualURL = url.wrappedValue {
                SafariView(url: actualURL)
                    .ignoresSafeArea()
            }
        }
    }
}
#endif
