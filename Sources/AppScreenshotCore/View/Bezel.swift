//  Bezel.swift
//  AppScreenshotKit
//
//  Created by Shuhei Shitamori on 2025/04/25.
//

import SwiftUI

/// A view that renders app content within a device bezel frame.
struct Bezel<Content: View>: View {
    @Environment(\.deviceModel) var model: DeviceViewModel
    let bezelImageData: Data
    let content: Content
    private let seamOverlap: CGFloat = 1

    init(bezelImageData: Data, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.bezelImageData = bezelImageData
    }

    var body: some View {
        GeometryReader { proxy in
            let bezelDefinition = model.appldeBezelDefinition
            let scale = min(
                proxy.size.width / bezelDefinition.imageSize.width,
                proxy.size.height / bezelDefinition.imageSize.height
            )
            let renderedImageSize = CGSize(
                width: bezelDefinition.imageSize.width * scale,
                height: bezelDefinition.imageSize.height * scale
            )
            let imageOrigin = CGPoint(
                x: (proxy.size.width - renderedImageSize.width) / 2,
                y: (proxy.size.height - renderedImageSize.height) / 2
            )
            let scaledScreenRect = CGRect(
                x: imageOrigin.x + bezelDefinition.screenRect.origin.x * scale,
                y: imageOrigin.y + bezelDefinition.screenRect.origin.y * scale,
                width: bezelDefinition.screenRect.width * scale,
                height: bezelDefinition.screenRect.height * scale
            ).insetBy(dx: -seamOverlap, dy: -seamOverlap)

            ZStack {
                ScreenContentView {
                    content
                }
                .frame(width: scaledScreenRect.width, height: scaledScreenRect.height)
                .position(x: scaledScreenRect.midX, y: scaledScreenRect.midY)

                Image(data: bezelImageData)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
        .frame(width: model.deviceViewSize.width, height: model.deviceViewSize.height)
    }
}

extension Image {
    init(data: Data) {
        #if canImport(UIKit)
            let uiImage = UIImage(data: data) ?? UIImage()
            self.init(uiImage: uiImage)
        #elseif canImport(AppKit)
            let nsImage = NSImage(data: data) ?? NSImage()
            self.init(nsImage: nsImage)
        #endif
    }
}
