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
            window.setNeedsLayout()
            window.layoutIfNeeded()

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
                // UIKit recommends snapshotting the entire UIWindow when visual
                // effects are present. Falling back to the hosted view keeps
                // older/non-scene-backed contexts working.
                if !window.drawHierarchy(in: window.bounds, afterScreenUpdates: true),
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
}
