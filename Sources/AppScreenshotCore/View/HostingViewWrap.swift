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
            applySafeAreaInsets(to: myViewController, environment: context.environment)
            return myViewController
        }

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
                left: 0,
                bottom: insets.bottom,
                right: 0
            )

            // Set nav bar layout margins directly for title padding,
            // without affecting the content's safe area.
            DispatchQueue.main.async {
                self.applyNavBarMargins(from: viewController.view)
            }
        }

        private func applyNavBarMargins(from view: UIView) {
            if let navBar = view as? UINavigationBar {
                navBar.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
                return
            }
            for subview in view.subviews {
                applyNavBarMargins(from: subview)
            }
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
