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

/// Whether the ScreenContentView should use an explicit frame (for screenshot export).
struct ScreenContentExplicitFrameEnvironmentKey: EnvironmentKey {
    static let defaultValue: Bool = true
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

    /// Whether ScreenContentView should use an explicit frame.
    /// Set to false when the parent controls the size (e.g., inside DeviceView).
    var screenContentExplicitFrame: Bool {
        get { self[ScreenContentExplicitFrameEnvironmentKey.self] }
        set { self[ScreenContentExplicitFrameEnvironmentKey.self] = newValue }
    }

    /// The current AppScreenshotEnvironment in the environment.
    public var appScreenshotEnvironment: AppScreenshotEnvironment {
        get { self[AppScreenshotEnvironmentEnvironmentKey.self] }
        set { self[AppScreenshotEnvironmentEnvironmentKey.self] = newValue }
    }
}
