import SwiftUI

/// Protocol that defines the core functionality for generating App Store screenshots.
///
/// This protocol is the foundation of AppScreenshotKit, allowing you to define
/// how your App Store screenshots should be rendered across different devices,
/// orientations, and locales.
public protocol AppScreenshot {
    associatedtype Content: View

    /// The configuration that defines which devices, orientations, and locales
    /// will be used for screenshot generation.
    static var configuration: AppScreenshotConfiguration { get }

    /// Builds the content view for the screenshot.
    ///
    /// This method is where you define the actual appearance of your screenshots.
    /// It will be called for each device and locale combination specified in your configuration.
    ///
    /// - Parameter environment: The environment containing contextual information about
    ///   the current screenshot being rendered, including device information and locale.
    /// - Returns: A SwiftUI view that will be rendered as the screenshot.
    @MainActor static func body(environment: AppScreenshotEnvironment) -> Content
}

extension AppScreenshot {
    /// Creates and configures the screenshot view with the appropriate environment settings.
    ///
    /// This method applies the necessary frame constraints, device environment values,
    /// and other configurations to ensure the screenshot is rendered correctly.
    ///
    /// - Parameter environment: The environment context for the screenshot.
    /// - Returns: A configured view ready for screenshot rendering.
    @MainActor static func screenshotView(environment: AppScreenshotEnvironment) -> some View {
        screenshotRootView(environment: environment)
    }

    @MainActor
    @ViewBuilder
    private static func screenshotRootView(environment: AppScreenshotEnvironment) -> some View {
        #if canImport(UIKit)
            UIScreenBoundsBootstrap(
                screenSize: environment.device.screenSize,
                idiom: uiUserInterfaceIdiom(from: environment.device.model.category)
            ) {
                screenshotBodyView(environment: environment)
            }
        #else
            screenshotBodyView(environment: environment)
        #endif
    }

    @MainActor static func screenshotBodyView(environment: AppScreenshotEnvironment) -> some View {
        body(environment: environment)
            .frame(
                width: environment.canvasSize.width,
                height: environment.canvasSize.height
            )
            .clipped()
            .environment(\.deviceModel, environment.device)
            .environment(\.locale, environment.locale)
            .environment(
                \.verticalSizeClass,
                environment.device.verticalSizeClass
            )
            .environment(
                \.horizontalSizeClass,
                environment.device.horizontalSizeClass
            )
    }
}

#if canImport(UIKit)
    import UIKit

    struct UIScreenBoundsBootstrap<Content: View>: View {
        @StateObject private var token: UIScreenBoundsToken
        let content: Content

        init(screenSize: CGSize, idiom: UIUserInterfaceIdiom, @ViewBuilder content: () -> Content) {
            _token = StateObject(
                wrappedValue: UIScreenBoundsToken(screenSize: screenSize, idiom: idiom)
            )
            self.content = content()
        }

        var body: some View {
            content
        }
    }

    @MainActor
    final class UIScreenBoundsToken: ObservableObject {
        init(screenSize: CGSize, idiom: UIUserInterfaceIdiom) {
            UIScreenSwizzle.activate(screenSize, idiom: idiom)
        }

        deinit {
            Task { @MainActor in
                UIScreenSwizzle.deactivate()
            }
        }
    }
#endif
