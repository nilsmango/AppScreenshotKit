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
            let myViewController = UIHostingController(rootView: content)

            // Use safeAreaInsets from environment's deviceModel if available
            let deviceModel = context.environment.deviceModel
            let insets = deviceModel.safeAreaInsets
            myViewController.additionalSafeAreaInsets = UIEdgeInsets(
                top: insets.top,
                left: insets.leading,
                bottom: insets.bottom,
                right: insets.trailing
            )

            // Set layout margins so the navigation bar gets proper horizontal
            // padding for large titles without affecting SwiftUI content layout.
            myViewController.view.directionalLayoutMargins = NSDirectionalEdgeInsets(
                top: 0,
                leading: deviceModel.screenEdgePadding,
                bottom: 0,
                trailing: deviceModel.screenEdgePadding
            )

            return myViewController
        }

        /// Updates the hosted view controller’s safe area insets when the device model changes.
        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
            // Update safe area insets if device model changes
            let deviceModel = context.environment.deviceModel
            let insets = deviceModel.safeAreaInsets
            uiViewController.additionalSafeAreaInsets = UIEdgeInsets(
                top: insets.top,
                left: insets.leading,
                bottom: insets.bottom,
                right: insets.trailing
            )
            uiViewController.view.directionalLayoutMargins = NSDirectionalEdgeInsets(
                top: 0,
                leading: deviceModel.screenEdgePadding,
                bottom: 0,
                trailing: deviceModel.screenEdgePadding
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
