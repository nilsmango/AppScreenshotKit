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
        .frame(width: model.screenSize.width, height: model.screenSize.height)
        .clipped()
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
        .overlay {
            InverseRoundedRectangle(cornerRadius: model.bezelRadius)
                .fill(.black, style: FillStyle(eoFill: true))
        }
    }
}

private struct InverseRoundedRectangle: Shape {
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        path.addRoundedRect(
            in: rect,
            cornerSize: CGSize(width: cornerRadius, height: cornerRadius)
        )
        return path
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
        nonisolated(unsafe) private static var originalBoundsImp: IMP?
        nonisolated(unsafe) private static var originalIdiomImp: IMP?
        nonisolated(unsafe) private static var mainBoundsOverride: CGSize?
        nonisolated(unsafe) private static var userInterfaceIdiomOverride: UIUserInterfaceIdiom?
        private let lock = NSLock()
        private var refCount = 0

        nonisolated(unsafe) static let boundsSwizzleBlock: @convention(block) (UIScreen) -> CGRect = {
            screen in
            if let override = mainBoundsOverride {
                return CGRect(origin: .zero, size: override)
            }
            let fn = unsafeBitCast(
                originalBoundsImp,
                to: (@convention(c) (UIScreen, Selector) -> CGRect).self
            )
            return fn(screen, #selector(getter: UIScreen.bounds))
        }

        nonisolated(unsafe) static let idiomSwizzleBlock: @convention(block) (UIDevice) -> UIUserInterfaceIdiom = {
            device in
            if let override = userInterfaceIdiomOverride {
                return override
            }
            let fn = unsafeBitCast(
                originalIdiomImp,
                to: (@convention(c) (UIDevice, Selector) -> UIUserInterfaceIdiom).self
            )
            return fn(device, #selector(getter: UIDevice.userInterfaceIdiom))
        }

        @MainActor
        static func activate(_ screenSize: CGSize, idiom: UIUserInterfaceIdiom) {
            shared.lock.lock()
            shared.refCount += 1
            let isFirst = shared.refCount == 1
            shared.lock.unlock()

            mainBoundsOverride = screenSize
            userInterfaceIdiomOverride = idiom
            if isFirst {
                setup()
            }
        }

        @MainActor
        static func update(_ screenSize: CGSize, idiom: UIUserInterfaceIdiom) {
            mainBoundsOverride = screenSize
            userInterfaceIdiomOverride = idiom
            if originalBoundsImp == nil || originalIdiomImp == nil {
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
            userInterfaceIdiomOverride = nil
            if shouldTeardown {
                teardown()
            }
        }

        private static func setup() {
            guard let boundsMethod = class_getInstanceMethod(
                UIScreen.self,
                #selector(getter: UIScreen.bounds)
            ),
                let idiomMethod = class_getInstanceMethod(
                    UIDevice.self,
                    #selector(getter: UIDevice.userInterfaceIdiom)
                )
            else { return }
            originalBoundsImp = method_getImplementation(boundsMethod)
            originalIdiomImp = method_getImplementation(idiomMethod)
            let boundsBlock = imp_implementationWithBlock(boundsSwizzleBlock)
            let idiomBlock = imp_implementationWithBlock(idiomSwizzleBlock)
            method_setImplementation(boundsMethod, boundsBlock)
            method_setImplementation(idiomMethod, idiomBlock)
        }

        private static func teardown() {
            guard let boundsMethod = class_getInstanceMethod(
                UIScreen.self,
                #selector(getter: UIScreen.bounds)
            ),
                let idiomMethod = class_getInstanceMethod(
                    UIDevice.self,
                    #selector(getter: UIDevice.userInterfaceIdiom)
                ),
                let originalBoundsImp,
                let originalIdiomImp
            else { return }
            method_setImplementation(boundsMethod, originalBoundsImp)
            method_setImplementation(idiomMethod, originalIdiomImp)
            self.originalBoundsImp = nil
            self.originalIdiomImp = nil
        }
    }
#endif
