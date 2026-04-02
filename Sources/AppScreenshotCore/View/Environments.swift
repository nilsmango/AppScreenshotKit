//
//  Environments.swift
//  AppScreenshotKit
//
//  Created by Shuhei Shitamori on 2025/04/25.
//

import Foundation
import SwiftUI

/// An environment key for storing the current device model used in the screenshot environment.
struct DeviceModelEnvironmentKey: EnvironmentKey {
    static let defaultValue: DeviceViewModel = AppScreenshotDevice(
        orientation: .portrait,
        color: .black,
        model: .iPhone17Pro
    )
}

/// An environment key for storing the rendering strategy (virtual or real device).
struct RenderingStrategyEnvironmentKey: EnvironmentKey {
    static let defaultValue: RenderingStrategy = .virtual
}

/// An environment key for indicating whether the status bar is shown.
struct StatusBarShownEnvironmentKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

/// An environment key that indicates when the view is being rendered for export.
struct ExportRenderingEnvironmentKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

/// An environment key for storing the current AppScreenshotEnvironment.
struct AppScreenshotEnvironmentEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppScreenshotEnvironment = AppScreenshotEnvironment(
        screenshotSize: .zero,
        tileCount: 1,
        canvasSize: .zero,
        locale: .current,
        device: AppScreenshotDevice(
            orientation: .portrait,
            color: .black,
            model: .iPhone17Pro
        )
    )
}

extension EnvironmentValues {
    /// The current device model in the environment.
    var deviceModel: DeviceViewModel {
        get { self[DeviceModelEnvironmentKey.self] }
        set { self[DeviceModelEnvironmentKey.self] = newValue }
    }

    /// The rendering strategy in the environment.
    var renderingStrategy: RenderingStrategy {
        get { self[RenderingStrategyEnvironmentKey.self] }
        set { self[RenderingStrategyEnvironmentKey.self] = newValue }
    }

    /// Whether the status bar is shown in the environment.
    var statusBarShown: Bool {
        get { self[StatusBarShownEnvironmentKey.self] }
        set { self[StatusBarShownEnvironmentKey.self] = newValue }
    }

    /// Whether the view is being rendered through the screenshot export path.
    var isExportRendering: Bool {
        get { self[ExportRenderingEnvironmentKey.self] }
        set { self[ExportRenderingEnvironmentKey.self] = newValue }
    }

    /// The current AppScreenshotEnvironment in the environment.
    public var appScreenshotEnvironment: AppScreenshotEnvironment {
        get { self[AppScreenshotEnvironmentEnvironmentKey.self] }
        set { self[AppScreenshotEnvironmentEnvironmentKey.self] = newValue }
    }
}
