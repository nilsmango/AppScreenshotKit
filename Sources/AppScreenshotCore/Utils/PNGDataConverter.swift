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
            if #available(iOS 16.0, *) {
                let renderer = ImageRenderer(content: content)
                renderer.scale = scale
                renderer.isOpaque = false
                renderer.colorMode = .nonLinear

                guard let uiImage = renderer.uiImage else {
                    return Data()
                }

                return try imageData(from: uiImage, rect: rect, imageFormat: imageFormat)
            } else {
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

                let format = UIGraphicsImageRendererFormat()
                format.scale = scale
                format.opaque = false

                let renderRect = rect ?? CGRect(origin: .zero, size: targetSize)
                let renderer = UIGraphicsImageRenderer(size: renderRect.size, format: format)
                let render: (UIGraphicsImageRendererContext) -> Void = { ctx in
                    ctx.cgContext.translateBy(x: -renderRect.origin.x, y: -renderRect.origin.y)
                    _ = view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
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
        private func imageData(
            from image: UIImage,
            rect: CGRect?,
            imageFormat: AppScreenshotImageFormat
        ) throws -> Data {
            let sourceImage = try croppedImage(from: image, rect: rect)
            switch imageFormat {
            case .png:
                return sourceImage.pngData() ?? Data()
            case .jpeg:
                return sourceImage.jpegData(
                    compressionQuality: imageFormat.clampedCompressionQuality
                ) ?? Data()
            }
        }

        private func croppedImage(from image: UIImage, rect: CGRect?) throws -> UIImage {
            guard let rect else { return image }
            guard let cgImage = image.cgImage else { return image }

            let cropRect = CGRect(
                x: rect.origin.x * image.scale,
                y: rect.origin.y * image.scale,
                width: rect.size.width * image.scale,
                height: rect.size.height * image.scale
            ).integral

            guard let croppedCGImage = cgImage.cropping(to: cropRect) else { return image }
            return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: .up)
        }
    #endif
}
