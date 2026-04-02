//
//  HostingViewWrap.swift
//  AppScreenshotKit
//
//  Created by Shuhei Shitamori on 2025/05/10.
//

import SwiftUI

#if canImport(UIKit)
    import UIKit

    /// A UIViewControllerRepresentable that wraps SwiftUI content for UIKit hosting.
    struct HostingViewWrap<Content: View>: UIViewControllerRepresentable {
        typealias UIViewControllerType = UIHostingController<Content>

        let content: Content

        init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }

        func makeUIViewController(context: Context) -> UIHostingController<Content> {
            activateUIScreenSwizzle(environment: context.environment)
            let hostingController = UIHostingController(rootView: content)
            hostingController.view.backgroundColor = .clear
            applySafeAreaInsets(to: hostingController, environment: context.environment)
            return hostingController
        }

        func updateUIViewController(_ uiViewController: UIHostingController<Content>, context: Context) {
            updateUIScreenSwizzle(environment: context.environment)
            uiViewController.rootView = content
            applySafeAreaInsets(to: uiViewController, environment: context.environment)
        }

        static func dismantleUIViewController(_ uiViewController: UIHostingController<Content>, coordinator: ()) {
            UIScreenSwizzle.deactivate()
        }

        func sizeThatFits(
            _ proposal: ProposedViewSize,
            uiViewController: UIHostingController<Content>,
            context: Context
        ) -> CGSize? {
            context.environment.deviceModel.screenSize
        }

        private func applySafeAreaInsets(
            to viewController: UIHostingController<Content>,
            environment: EnvironmentValues
        ) {
            viewController.additionalSafeAreaInsets = uiEdgeInsets(
                from: environment.deviceModel.safeAreaInsets
            )

            // Set nav bar layout margins directly for title padding,
            // without affecting the content's safe area.
            DispatchQueue.main.async {
                self.applyNavBarMargins(from: viewController.view)
            }
        }

        private func activateUIScreenSwizzle(environment: EnvironmentValues) {
            UIScreenSwizzle.activate(environment.deviceModel.screenSize)
        }

        private func updateUIScreenSwizzle(environment: EnvironmentValues) {
            UIScreenSwizzle.update(environment.deviceModel.screenSize)
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

#if canImport(UIKit)
    func uiEdgeInsets(from insets: EdgeInsets) -> UIEdgeInsets {
        UIEdgeInsets(
            top: insets.top,
            left: insets.leading,
            bottom: insets.bottom,
            right: insets.trailing
        )
    }
#endif
