//
//  HostingViewWrap.swift
//  AppScreenshotKit
//
//  Created by Shuhei Shitamori on 2025/05/10.
//

import SwiftUI

#if canImport(UIKit)
    /// A UIViewControllerRepresentable that wraps SwiftUI content for UIKit hosting.
    struct HostingViewWrap<Content: View>: UIViewControllerRepresentable {

        let content: Content

        init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }

        func makeUIViewController(context: Context) -> UIViewController {
            let myViewController = UIHostingController(
                rootView: content.ignoresSafeArea(.container, edges: .horizontal)
            )
            applySafeAreaInsets(to: myViewController, environment: context.environment)
            return myViewController
        }

        /// Updates the hosted view controller's safe area insets when the device model changes.
        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
            applySafeAreaInsets(to: uiViewController, environment: context.environment)
        }

        private func applySafeAreaInsets(
            to viewController: UIViewController,
            environment: EnvironmentValues
        ) {
            let insets = environment.deviceModel.safeAreaInsets
            viewController.additionalSafeAreaInsets = UIEdgeInsets(
                top: insets.top,
                left: 16,
                bottom: insets.bottom,
                right: 16
            )
        }
    }
#else
    struct HostingViewWrap<Content: View>: View {

        let content: Content

        init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }

        var body: some View {
            content
        }
    }
#endif
