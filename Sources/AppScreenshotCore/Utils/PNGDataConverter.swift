import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

@MainActor
struct PNGDataConverter {
    func convert<Content: View>(
        _ content: Content,
        rect: CGRect? = nil,
        scale: CGFloat = 1,
        imageFormat: AppScreenshotImageFormat = .png
    ) throws -> Data {
        #if canImport(UIKit)
            return try convertUIKit(
                content,
                rect: rect,
                scale: scale,
                imageFormat: imageFormat
            )
        #elseif canImport(AppKit)
            return convertAppKit(
                content,
                rect: rect,
                scale: scale,
                imageFormat: imageFormat
            )
        #endif
    }
}

    #if canImport(UIKit)
    extension PNGDataConverter {
        fileprivate func convertUIKit<Content: View>(
            _ content: Content,
            rect: CGRect?,
            scale: CGFloat,
            imageFormat: AppScreenshotImageFormat
        ) throws -> Data {
            let controller = UIHostingController(rootView: content)
            if #available(iOS 16.4, *) {
                controller.safeAreaRegions = []
            }

            let view = controller.view!
            view.backgroundColor = .clear

            let targetSize = controller.sizeThatFits(
                in: CGSize(
                    width: CGFloat.greatestFiniteMagnitude,
                    height: CGFloat.greatestFiniteMagnitude
                )
            )
            let resolvedSize: CGSize
            if targetSize.width > 0, targetSize.height > 0 {
                resolvedSize = targetSize
            } else {
                resolvedSize = CGSize(width: 1290, height: 2796)
            }

            let keyWindowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first

            view.frame = CGRect(origin: .zero, size: resolvedSize)
            view.setNeedsLayout()
            view.layoutIfNeeded()

            let captureRect = rect ?? CGRect(origin: .zero, size: resolvedSize)

            if let keyWindowScene {
                let renderWindow = UIWindow(windowScene: keyWindowScene)
                renderWindow.frame = CGRect(origin: .zero, size: resolvedSize)
                renderWindow.rootViewController = controller
                renderWindow.isHidden = false
                renderWindow.makeKeyAndVisible()

                for _ in 0..<30 {
                    RunLoop.main.run(until: Date().addingTimeInterval(0.05))
                    view.setNeedsLayout()
                    view.layoutIfNeeded()
                }

                let rendererFormat = UIGraphicsImageRendererFormat()
                rendererFormat.scale = scale
                rendererFormat.opaque = false

                let renderer = UIGraphicsImageRenderer(size: captureRect.size, format: rendererFormat)
                let data: Data
                switch imageFormat {
                case .png:
                    data = renderer.pngData { ctx in
                        ctx.cgContext.translateBy(x: -captureRect.origin.x, y: -captureRect.origin.y)
                        renderWindow.drawHierarchy(in: renderWindow.bounds, afterScreenUpdates: true)
                    }
                case .jpeg:
                    data = renderer.jpegData(
                        withCompressionQuality: imageFormat.clampedCompressionQuality
                    ) { ctx in
                        ctx.cgContext.translateBy(x: -captureRect.origin.x, y: -captureRect.origin.y)
                        renderWindow.drawHierarchy(in: renderWindow.bounds, afterScreenUpdates: true)
                    }
                }

                renderWindow.isHidden = true
                return data
            } else {
                for _ in 0..<20 {
                    RunLoop.main.run(until: Date().addingTimeInterval(0.05))
                    view.setNeedsLayout()
                    view.layoutIfNeeded()
                }

                let rendererFormat = UIGraphicsImageRendererFormat()
                rendererFormat.scale = scale
                rendererFormat.opaque = false

                let renderer = UIGraphicsImageRenderer(size: captureRect.size, format: rendererFormat)
                switch imageFormat {
                case .png:
                    return renderer.pngData { ctx in
                        ctx.cgContext.translateBy(x: -captureRect.origin.x, y: -captureRect.origin.y)
                        view.layer.render(in: ctx.cgContext)
                    }
                case .jpeg:
                    return renderer.jpegData(
                        withCompressionQuality: imageFormat.clampedCompressionQuality
                    ) { ctx in
                        ctx.cgContext.translateBy(x: -captureRect.origin.x, y: -captureRect.origin.y)
                        view.layer.render(in: ctx.cgContext)
                    }
                }
            }
        }
    }
#endif

#if canImport(AppKit) && !canImport(UIKit)
    import AppKit

    extension PNGDataConverter {
        fileprivate func convertAppKit<Content: View>(
            _ content: Content,
            rect: CGRect?,
            scale: CGFloat,
            imageFormat: AppScreenshotImageFormat
        ) -> Data {
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
        }
    }
#endif
