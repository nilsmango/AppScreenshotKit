//
//  PNGDataConverter.swift
//  AppScreenshotKit
//
//  Created by Shuhei Shitamori on 2025/04/25.
//

import SwiftUI

#if canImport(UIKit)
    import QuartzCore
#endif

@MainActor
struct PNGDataConverter {
    /// Convert a SwiftUI view to image data in the specified format
    func convert<Content: View>(
        _ content: Content,
        rect: CGRect? = nil,
        scale: CGFloat = 1,
        imageFormat: AppScreenshotImageFormat = .png
    ) throws -> Data {
        #if canImport(UIKit)
            let controller = UIHostingController(rootView: content)
            if #available(iOS 16.4, *) {
                controller.safeAreaRegions = []
            }
            let view = controller.view!
            let targetSize = controller.view.intrinsicContentSize
            view.bounds = CGRect(origin: .zero, size: targetSize)
            view.frame = CGRect(origin: .zero, size: targetSize)
            view.backgroundColor = .clear

            let mountedHost = mountHostView(
                controllerView: view,
                targetSize: targetSize
            )
            defer {
                mountedHost.teardown()
            }

            view.sizeToFit()
            view.setNeedsLayout()
            view.layoutIfNeeded()
            mountedHost.window.setNeedsLayout()
            mountedHost.window.layoutIfNeeded()

            // Give UIKit's render server a chance to commit the visual-effect tree
            // before snapshotting; otherwise drawHierarchy can fail and material
            // falls back to layer.render(in:), which drops the effect entirely.
            CATransaction.flush()
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
            CATransaction.flush()

            let renderRect = rect ?? CGRect(origin: .zero, size: targetSize)
            let format = UIGraphicsImageRendererFormat()
            format.scale = scale
            format.opaque = false
            let renderer = UIGraphicsImageRenderer(size: renderRect.size, format: format)
            let render: (UIGraphicsImageRendererContext) -> Void = { ctx in
                ctx.cgContext.translateBy(x: -renderRect.origin.x, y: -renderRect.origin.y)
                if (mountedHost.usesDedicatedWindow
                    && !mountedHost.window.drawHierarchy(in: mountedHost.window.bounds, afterScreenUpdates: true)),
                    !view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
                {
                    view.layer.render(in: ctx.cgContext)
                }
            }
            switch imageFormat {
            case .png:
                return renderer.pngData(actions: render)
            case .jpeg:
                return renderer.jpegData(
                    withCompressionQuality: imageFormat.clampedCompressionQuality,
                    actions: render
                )
            }
        #elseif canImport(AppKit)
            let view = NSHostingView(rootView: content)
            let targetSize = view.intrinsicContentSize
            view.frame = NSRect(origin: .zero, size: targetSize)

            guard let bitmapRep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else {
                return Data()
            }

            view.cacheDisplay(in: view.bounds, to: bitmapRep)
            let data: Data?
            switch imageFormat {
            case .png:
                data = bitmapRep.representation(using: .png, properties: [:])
            case .jpeg:
                data = bitmapRep.representation(
                    using: .jpeg,
                    properties: [.compressionFactor: imageFormat.clampedCompressionQuality]
                )
            }
            guard let data else { return Data() }

            return data
        #endif
    }

    #if canImport(UIKit)
        private func mountHostView(
            controllerView: UIView,
            targetSize: CGSize
        ) -> MountedHostView {
            if let existingWindow = activeHostWindow() {
                let container = UIView(frame: CGRect(x: 10_000, y: 10_000, width: targetSize.width, height: targetSize.height))
                container.backgroundColor = .clear
                container.clipsToBounds = false
                controllerView.frame = container.bounds
                controllerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                container.addSubview(controllerView)
                existingWindow.addSubview(container)
                return MountedHostView(
                    window: existingWindow,
                    containerView: container,
                    usesDedicatedWindow: false
                )
            }

            let window = UIWindow()
            window.frame = CGRect(origin: .zero, size: targetSize)
            if let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState != .unattached })
            {
                window.windowScene = scene
            }
            let rootController = UIViewController()
            rootController.view.backgroundColor = .clear
            rootController.view.frame = window.bounds
            window.rootViewController = rootController
            window.makeKeyAndVisible()

            controllerView.frame = rootController.view.bounds
            controllerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            rootController.view.addSubview(controllerView)

            return MountedHostView(
                window: window,
                containerView: rootController.view,
                usesDedicatedWindow: true
            )
        }

        private func activeHostWindow() -> UIWindow? {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .sorted { lhs, rhs in
                    activationRank(lhs.activationState) < activationRank(rhs.activationState)
                }
                .flatMap(\.windows)
                .first { !$0.isHidden && $0.rootViewController != nil }
        }

        private func activationRank(_ state: UIScene.ActivationState) -> Int {
            switch state {
            case .foregroundActive:
                0
            case .foregroundInactive:
                1
            case .background:
                2
            case .unattached:
                3
            @unknown default:
                4
            }
        }

        private struct MountedHostView {
            let window: UIWindow
            let containerView: UIView
            let usesDedicatedWindow: Bool

            func teardown() {
                if usesDedicatedWindow {
                    window.isHidden = true
                    window.rootViewController = nil
                } else {
                    containerView.removeFromSuperview()
                }
            }
        }
    #endif
}
