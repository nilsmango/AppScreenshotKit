//
//  ScreenContentView.swift
//  AppScreenshotKit
//
//  Created by Shuhei Shitamori on 2025/04/25.
//

import SwiftUI

/// A view that renders the main screen content for a device, including status bar handling.
struct ScreenContentView<Content: View>: View {

    let content: Content
    @Environment(\.deviceModel) var model: DeviceViewModel
    @Environment(\.statusBarShown) var statusBarShown

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HostingViewWrap {
            content
        }
        .background {
            NavigationBarMarginFix(edgePadding: screenEdgePadding)
                .allowsHitTesting(false)
        }
        .frame(width: model.screenSize.width, height: model.screenSize.height)
        .overlay(alignment: .top) {
            if statusBarShown {
                HStack(spacing: 0) {
                    Text("09:41")
                        .font(.system(size: 17, weight: .semibold))
                        .padding(.leading)
                        .padding(.leading)
                        .padding(.trailing, 6)

                    if let dynamicIdsand = model.dynamicIdsand {
                        Spacer()
                            .frame(minWidth: dynamicIdsand.size.width)
                    } else {
                        Spacer()
                    }

                    HStack(spacing: 7) {

                        Image(systemName: "cellularbars")
                            .font(.system(size: 17))
                            .padding(.leading, 6)

                        Image(systemName: "wifi")
                            .font(.system(size: 17))

                        Image(systemName: "battery.100percent")
                            .font(.system(size: 17))
                            .padding(.trailing)
                    }
                    .padding(.trailing)
                }
                .foregroundStyle(.primary)
                .frame(height: model.safeAreaInsets.top)
                .ignoresSafeArea()
            }
        }
        #if canImport(UIKit)
            .background(Color(uiColor: .systemBackground))
        #elseif canImport(AppKit)
            .background(Color(NSColor.windowBackgroundColor))
        #endif
        .clipShape(
            RoundedRectangle(
                cornerRadius: model.bezelRadius
            )
        )
    }

    private var screenEdgePadding: CGFloat {
        // iPhones with Dynamic Island need horizontal padding for the large
        // navigation title; iPads and older iPhones without it don't.
        model.dynamicIdsand != nil ? 16 : 0
    }
}

#if canImport(UIKit)
    /// Finds the UINavigationBar in the ancestor view hierarchy and sets its layout margins
    /// so large navigation titles get proper horizontal padding.
    private struct NavigationBarMarginFix: UIViewControllerRepresentable {
        let edgePadding: CGFloat

        func makeUIViewController(context: Context) -> UIViewController {
            let vc = UIViewController()
            vc.view.backgroundColor = .clear
            vc.view.isUserInteractionEnabled = false
            return vc
        }

        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
            guard let navBar = findNavigationBar(from: uiViewController) else { return }
            navBar.layoutMargins = UIEdgeInsets(
                top: 0,
                left: edgePadding,
                bottom: 0,
                right: edgePadding
            )
        }

        private func findNavigationBar(from viewController: UIViewController) -> UINavigationBar? {
            // Check parent hierarchy
            var current = viewController.parent
            while let parent = current {
                if let nav = parent as? UINavigationController {
                    return nav.navigationBar
                }
                for child in parent.children {
                    if let nav = child as? UINavigationController {
                        return nav.navigationBar
                    }
                }
                current = parent
            }
            // Check sibling/ancestor view hierarchy
            var view: UIView? = viewController.view.superview
            while view != nil {
                if let navBar = findNavBarInHierarchy(view!) {
                    return navBar
                }
                view = view?.superview
            }
            return nil
        }

        private func findNavBarInHierarchy(_ view: UIView) -> UINavigationBar? {
            if let navBar = view as? UINavigationBar {
                return navBar
            }
            for subview in view.subviews {
                if let navBar = subview as? UINavigationBar {
                    return navBar
                }
                if let navBar = findNavBarInHierarchy(subview) {
                    return navBar
                }
            }
            return nil
        }
    }
#endif
