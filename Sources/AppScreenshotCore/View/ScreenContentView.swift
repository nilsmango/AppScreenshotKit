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
            #if canImport(UIKit)
                Color.clear
                    .onAppear { UIScreenSwizzle.activate(model.screenSize) }
                    .onDisappear { UIScreenSwizzle.deactivate() }
                    .allowsHitTesting(false)
            #endif
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
}

#if canImport(UIKit)
    import ObjectiveC
    import UIKit

    /// Swizzles `UIScreen.main.bounds` to return the simulated device screen size
    /// while a DeviceView is rendering. This ensures code that reads
    /// `UIScreen.main.bounds.size` gets the correct device dimensions.
    final class UIScreenSwizzle: NSObject, @unchecked Sendable {
        static let shared = UIScreenSwizzle()
        nonisolated(unsafe) private static var originalImp: IMP?
        nonisolated(unsafe) private static var mainBoundsOverride: CGSize?
        private let lock = NSLock()
        private var refCount = 0

        nonisolated(unsafe) static let swizzleBlock: @convention(block) (UIScreen) -> CGRect = {
            screen in
            if let override = mainBoundsOverride {
                return CGRect(origin: .zero, size: override)
            }
            let fn = unsafeBitCast(originalImp, to: (@convention(c) (UIScreen, Selector) -> CGRect).self)
            return fn(screen, #selector(getter: UIScreen.bounds))
        }

        @MainActor
        static func activate(_ screenSize: CGSize) {
            shared.lock.lock()
            shared.refCount += 1
            let isFirst = shared.refCount == 1
            shared.lock.unlock()

            mainBoundsOverride = screenSize
            if isFirst {
                setup()
            }
        }

        @MainActor
        static func deactivate() {
            shared.lock.lock()
            shared.refCount -= 1
            let shouldTeardown = shared.refCount <= 0
            if shouldTeardown { shared.refCount = 0 }
            shared.lock.unlock()

            mainBoundsOverride = nil
            if shouldTeardown {
                teardown()
            }
        }

        private static func setup() {
            guard let method = class_getInstanceMethod(
                UIScreen.self,
                #selector(getter: UIScreen.bounds)
            ) else { return }
            originalImp = method_getImplementation(method)
            let block = imp_implementationWithBlock(swizzleBlock)
            method_setImplementation(method, block)
        }

        private static func teardown() {
            guard let method = class_getInstanceMethod(
                UIScreen.self,
                #selector(getter: UIScreen.bounds)
            ), let orig = originalImp else { return }
            method_setImplementation(method, orig)
            originalImp = nil
        }
    }
#endif
