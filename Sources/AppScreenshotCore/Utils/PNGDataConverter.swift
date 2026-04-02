//
//  PNGDataConverter.swift
//  AppScreenshotKit
//
//  Created by Shuhei Shitamori on 2025/04/25.
//

import SwiftUI

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
            view.backgroundColor = .clear

            let window = UIWindow()
            window.frame = CGRect(origin: .zero, size: targetSize)
            if let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState != .unattached })
            {
                window.windowScene = scene
            }
            window.rootViewController = controller
            window.makeKeyAndVisible()

            view.sizeToFit()
            view.setNeedsLayout()
            view.layoutIfNeeded()

            // Positioning the hosted view far off-screen avoids transient
            // composition artifacts during snapshot rendering on recent toolchains.
            view.frame.origin = .init(x: 10_000, y: 10_000)

            let renderRect = rect ?? CGRect(origin: .zero, size: targetSize)
            let format = UIGraphicsImageRendererFormat()
            format.scale = scale
            format.opaque = false
            let renderer = UIGraphicsImageRenderer(size: renderRect.size, format: format)
            let render: (UIGraphicsImageRendererContext) -> Void = { ctx in
                ctx.cgContext.translateBy(x: -renderRect.origin.x, y: -renderRect.origin.y)
                // `drawHierarchy(in:afterScreenUpdates:)` preserves SwiftUI-backed
                // visual effects such as `.thinMaterial`, which are lost when the
                // hierarchy is flattened through `layer.render(in:)`.
                if !view.drawHierarchy(in: view.bounds, afterScreenUpdates: true) {
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
}
