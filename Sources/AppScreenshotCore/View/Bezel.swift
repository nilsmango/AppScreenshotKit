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

    init(bezelImageData: Data, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.bezelImageData = bezelImageData
    }

    var body: some View {
        GeometryReader { proxy in
            let bezelImage = Image(data: bezelImageData)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: proxy.size.width, height: proxy.size.height)

            ZStack {
                ScreenContentView {
                    content
                }
                .scaleEffect(
                    CGSize(
                        width: proxy.size.width / model.deviceViewSize.width,
                        height: proxy.size.height / model.deviceViewSize.height
                    )
                )
                .position(x: proxy.frame(in: .local).midX, y: proxy.frame(in: .local).midY)

                // Fill only where the bezel image has alpha, so fallback color
                // does not appear as a full rectangle behind the device.
                Color.black
                    .mask { bezelImage }

                bezelImage
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
