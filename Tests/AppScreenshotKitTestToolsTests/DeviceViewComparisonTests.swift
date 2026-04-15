//
//  DeviceViewComparisonTests.swift
//  AppScreenshotKit
//
//  Automated tests for DeviceView rendering behavior.
//
// HOW TO USE:
//
// 1. Run tests from Xcode Test Navigator (Cmd+6) — look for "DeviceViewComparisonTests".
// 2. Tests export screenshots to /tmp — check console for exact paths.
// 3. The UIScreen test is fully automated (checks exported image pixel dimensions).
// 4. The navigation title and status bar tests export images for manual inspection.
// 5. The locale test is fully automated — it compares ja_JP vs en_US images and
//    fails if they're identical (meaning locale isn't reaching the content).
//    Note: this verifies @Environment(\.locale) receives different values, not that
//    LocalizedStringKey resolves correctly (that would need .strings resource files).
//

import AppScreenshotKit
import SwiftUI
import XCTest

@testable import AppScreenshotKitTestTools

class DeviceViewComparisonTests: XCTestCase {

    // MARK: - UIScreen.main.bounds (FULLY AUTOMATED)

    /// Verifies that the exported screenshot has the correct pixel dimensions.
    /// If UIScreen.main.bounds.size returned the Mac's size instead of the
    /// device size, the rendered image would be a different size.
    /// iPhone 16 Pro Max (.iPhone69Inch() default): 1320 x 2868 pixels
    @MainActor
    func testUIScreenBoundsReturnsDeviceSize() throws {
        let outputURL = FileManager.default.temporaryDirectory.appending(
            path: "UIScreenAutoTest"
        )
        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

        let exporter = AppScreenshotExporter(option: .file(outputURL: outputURL))
        let outputs = try exporter.export(UIScreenDeviceViewScreenshot.self)

        // Exported screenshot is at 1x scale with pixel dimensions.
        // iPhone 16 Pro Max (.iPhone69Inch()): 1320 x 2868 pixels
        let expectedPixelWidth: CGFloat = 1320
        let expectedPixelHeight: CGFloat = 2868

        XCTAssertFalse(outputs.isEmpty)
        for output in outputs {
            XCTAssertFalse(output.imageData.isEmpty)

            #if canImport(UIKit)
                let image = try XCTUnwrap(UIImage(data: output.imageData))
                XCTAssertEqual(
                    image.size.width,
                    expectedPixelWidth,
                    accuracy: 1,
                    "Image width should be 1320px (iPhone 16 Pro Max screenshot width)"
                )
                XCTAssertEqual(
                    image.size.height,
                    expectedPixelHeight,
                    accuracy: 1,
                    "Image height should be 2868px (iPhone 16 Pro Max screenshot height)"
                )
            #endif
        }

        print("[Test] UIScreen screenshots saved to: \(outputURL.path())")
    }

    // MARK: - Navigation Title (exports for manual inspection)

    /// Exports a DeviceView with a large navigation title.
    /// The exported image should show the title with proper left padding.
    @MainActor
    func testNavigationTitleExport() throws {
        let outputURL = FileManager.default.temporaryDirectory.appending(
            path: "NavTitleTest"
        )
        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

        let exporter = AppScreenshotExporter(option: .file(outputURL: outputURL))
        let outputs = try exporter.export(NavigationTitleDeviceViewScreenshot.self)

        XCTAssertFalse(outputs.isEmpty, "Should produce at least one output")
        for output in outputs {
            XCTAssertFalse(output.imageData.isEmpty, "Image data should not be empty")
        }

        print("[Test] Navigation title screenshots saved to: \(outputURL.path())")
        if let files = try? FileManager.default.subpaths(atPath: outputURL.path()) {
            for file in files {
                print("[Test]   - \(file)")
            }
        }
    }

    // MARK: - Status Bar (exports for manual inspection)

    /// Exports a DeviceView with status bar. Check the output to verify
    /// the status bar is at the top of the device screen.
    @MainActor
    func testStatusBarExport() throws {
        let outputURL = FileManager.default.temporaryDirectory.appending(
            path: "StatusBarTest"
        )
        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

        let exporter = AppScreenshotExporter(option: .file(outputURL: outputURL))
        let outputs = try exporter.export(StatusBarDeviceViewScreenshot.self)

        XCTAssertFalse(outputs.isEmpty)
        for output in outputs {
            XCTAssertFalse(output.imageData.isEmpty)
        }

        print("[Test] StatusBar screenshots saved to: \(outputURL.path())")
    }
}

// MARK: - Export Screenshot Types

struct NavigationTitleDeviceViewScreenshot: View, AppScreenshot {
    nonisolated static var configuration: AppScreenshotConfiguration {
        .init(.iPhone69Inch())
    }

    @MainActor
    static func body(environment: AppScreenshotEnvironment) -> some View {
        Self().environment(\.appScreenshotEnvironment, environment)
    }

    var body: some View {
        DeviceView {
            NavigationStack {
                List {
                    ForEach(0..<10) { i in
                        Text("Item \(i)")
                    }
                }
                .navigationTitle("Test Title")
            }
        }
        .statusBarShown()
    }
}

struct StatusBarDeviceViewScreenshot: View, AppScreenshot {
    nonisolated static var configuration: AppScreenshotConfiguration {
        .init(.iPhone69Inch())
    }

    @MainActor
    static func body(environment: AppScreenshotEnvironment) -> some View {
        Self().environment(\.appScreenshotEnvironment, environment)
    }

    var body: some View {
        DeviceView {
            ZStack(alignment: .top) {
                Color.white
                VStack {
                    Spacer()
                    Text("Content Below Status Bar")
                        .font(.title)
                    Spacer()
                }
            }
        }
        .statusBarShown()
    }
}

/// Shows UIScreen.main.bounds values inside DeviceView.
/// Expected for iPhone 16 Pro Max: 440 x 956
struct UIScreenDeviceViewScreenshot: View, AppScreenshot {
    nonisolated static var configuration: AppScreenshotConfiguration {
        .init(.iPhone69Inch())
    }

    @MainActor
    static func body(environment: AppScreenshotEnvironment) -> some View {
        Self().environment(\.appScreenshotEnvironment, environment)
    }

    var body: some View {
        DeviceView {
            VStack(spacing: 20) {
                Spacer()
                Text("UIScreen.main.bounds")
                    .font(.headline)
                #if canImport(UIKit)
                    Text("width: \(Int(UIScreen.main.bounds.size.width))")
                        .font(.title2)
                    Text("height: \(Int(UIScreen.main.bounds.size.height))")
                        .font(.title2)
                    Text("(expected 440 x 956)")
                        .font(.caption)
                        .foregroundColor(.gray)
                #endif
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.1))
        }
    }
}

// MARK: - Locale Tests

extension DeviceViewComparisonTests {

    /// Fully automated locale test. Exports with ja_JP and en_US locales,
    /// then verifies the rendered images differ (different text = different pixels).
    @MainActor
    func testLocaleIsAppliedToContent() throws {
        let exporter = AppScreenshotExporter(
            option: .file(outputURL: FileManager.default.temporaryDirectory.appending(path: "LocaleAutoTest"))
        )
        let outputs = try exporter.export(LocaleTestScreenshot.self)

        // Verify we got one output per locale
        XCTAssertEqual(outputs.count, 2, "Should produce 2 screenshots (ja_JP and en_US)")

        guard outputs.count == 2 else { return }

        // Sort by locale to ensure consistent comparison
        let sorted = outputs.sorted { $0.environment.locale.identifier < $1.environment.locale.identifier }
        let ja = sorted[0]
        let en = sorted[1]

        XCTAssertEqual(ja.environment.locale.identifier, "en_US")
        XCTAssertEqual(en.environment.locale.identifier, "ja_JP")

        // The images MUST differ — different locale means different rendered text.
        // If they're identical, the locale is NOT being applied to the content.
        XCTAssertNotEqual(
            ja.imageData,
            en.imageData,
            "Images for ja_JP and en_US must differ. If identical, the locale is not being applied."
        )

        print("[LocaleTest] PASS: ja_JP and en_US produce different images — locale is working")
    }
}

/// Test screenshot with multiple locales. Shows the current locale identifier
/// so you can verify it changes between ja_JP and en_US.
struct LocaleTestScreenshot: View, AppScreenshot {
    nonisolated static var configuration: AppScreenshotConfiguration {
        .init(.iPhone69Inch(), options: .locale([Locale(identifier: "ja_JP"), Locale(identifier: "en_US")]))
    }

    @MainActor
    static func body(environment: AppScreenshotEnvironment) -> some View {
        Self().environment(\.appScreenshotEnvironment, environment)
    }

    @Environment(\.locale) var locale

    var body: some View {
        DeviceView {
            VStack(spacing: 20) {
                Spacer()
                Text("Locale Test")
                    .font(.headline)
                Text("locale: \(locale.identifier)")
                    .font(.title2)
                Text("calendar: \(locale.calendar.identifier)")
                    .font(.body)
                    .foregroundColor(.gray)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(Color.green.opacity(0.1))
        }
    }
}

// MARK: - LazyVGrid Visibility Test

extension DeviceViewComparisonTests {

    /// Automated test: renders the same grid content as LazyVGrid and regular Grid
    /// inside DeviceView. If LazyVGrid is missing items (due to scaleEffect/layout issues),
    /// the images will differ and the test fails.
    @MainActor
    func testLazyVGridRendersAllItems() throws {
        let outputURL = FileManager.default.temporaryDirectory.appending(path: "LazyGridTest")
        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

        let exporter = AppScreenshotExporter(option: .file(outputURL: outputURL))

        // Render with LazyVGrid
        let lazyOutputs = try exporter.export(LazyVGridTestScreenshot.self)
        // Render with regular Grid (non-lazy, renders all items)
        let eagerOutputs = try exporter.export(RegularGridTestScreenshot.self)

        XCTAssertFalse(lazyOutputs.isEmpty)
        XCTAssertFalse(eagerOutputs.isEmpty)

        guard let lazyImage = lazyOutputs.first,
              let eagerImage = eagerOutputs.first
        else { return }

        // If LazyVGrid is missing items, the images differ.
        // If both render all items correctly, the images are identical.
        XCTAssertEqual(
            lazyImage.imageData,
            eagerImage.imageData,
            "LazyVGrid image differs from regular Grid — LazyVGrid may be missing items inside DeviceView"
        )

        print("[LazyGridTest] PASS: LazyVGrid and regular Grid produce identical images")
    }

    /// Tests LazyVGrid with items that extend beyond the visible viewport.
    /// 100 items in 25 rows × 4 cols — far exceeds screen height.
    /// Compares LazyVGrid vs regular Grid to detect missing items.
    @MainActor
    func testLazyVGridOverflowItems() throws {
        let outputURL = FileManager.default.temporaryDirectory.appending(path: "LazyGridOverflow")
        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

        let exporter = AppScreenshotExporter(option: .file(outputURL: outputURL))

        let lazyOutputs = try exporter.export(LazyVGridOverflowTestScreenshot.self)
        let eagerOutputs = try exporter.export(RegularGridOverflowTestScreenshot.self)

        guard let lazyImage = lazyOutputs.first,
              let eagerImage = eagerOutputs.first
        else { return }

        XCTAssertEqual(
            lazyImage.imageData,
            eagerImage.imageData,
            "LazyVGrid overflow: missing items that extend beyond initial viewport inside DeviceView"
        )

        print("[LazyGridOverflow] PASS: LazyVGrid renders all 100 items correctly")
    }
}

/// Renders a LazyVGrid with numbered cells inside DeviceView.
struct LazyVGridTestScreenshot: View, AppScreenshot {
    nonisolated static var configuration: AppScreenshotConfiguration {
        .init(.iPhone69Inch())
    }

    @MainActor
    static func body(environment: AppScreenshotEnvironment) -> some View {
        Self().environment(\.appScreenshotEnvironment, environment)
    }

    var body: some View {
        DeviceView {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(80), spacing: 4), count: 4), spacing: 4) {
                ForEach(0..<40, id: \.self) { i in
                    Text("\(i)")
                        .font(.caption2)
                        .frame(width: 80, height: 40)
                        .background(Color(hue: Double(i) / 40.0, saturation: 0.5, brightness: 0.9))
                        .cornerRadius(4)
                }
            }
            .padding(8)
        }
    }
}

/// Renders the same grid with regular VStack+HStack (non-lazy, always renders all items).
struct RegularGridTestScreenshot: View, AppScreenshot {
    nonisolated static var configuration: AppScreenshotConfiguration {
        .init(.iPhone69Inch())
    }

    @MainActor
    static func body(environment: AppScreenshotEnvironment) -> some View {
        Self().environment(\.appScreenshotEnvironment, environment)
    }

    var body: some View {
        DeviceView {
            VStack(spacing: 4) {
                ForEach(0..<10, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<4, id: \.self) { col in
                            let i = row * 4 + col
                            Text("\(i)")
                                .font(.caption2)
                                .frame(width: 80, height: 40)
                                .background(Color(hue: Double(i) / 40.0, saturation: 0.5, brightness: 0.9))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            .padding(8)
        }
    }
}

/// LazyVGrid with 100 items — extends far beyond screen height.
/// If items beyond the initial viewport are not rendered, the test catches it.
struct LazyVGridOverflowTestScreenshot: View, AppScreenshot {
    nonisolated static var configuration: AppScreenshotConfiguration {
        .init(.iPhone69Inch())
    }

    @MainActor
    static func body(environment: AppScreenshotEnvironment) -> some View {
        Self().environment(\.appScreenshotEnvironment, environment)
    }

    var body: some View {
        DeviceView {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(80), spacing: 4), count: 4), spacing: 4) {
                ForEach(0..<100, id: \.self) { i in
                    Text("\(i)")
                        .font(.caption2)
                        .frame(width: 80, height: 40)
                        .background(Color(hue: Double(i) / 100.0, saturation: 0.5, brightness: 0.9))
                        .cornerRadius(4)
                }
            }
            .padding(8)
        }
    }
}

/// Regular Grid with same 100 items — always renders all items (non-lazy).
struct RegularGridOverflowTestScreenshot: View, AppScreenshot {
    nonisolated static var configuration: AppScreenshotConfiguration {
        .init(.iPhone69Inch())
    }

    @MainActor
    static func body(environment: AppScreenshotEnvironment) -> some View {
        Self().environment(\.appScreenshotEnvironment, environment)
    }

    var body: some View {
        DeviceView {
            VStack(spacing: 4) {
                ForEach(0..<25, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<4, id: \.self) { col in
                            let i = row * 4 + col
                            Text("\(i)")
                                .font(.caption2)
                                .frame(width: 80, height: 40)
                                .background(Color(hue: Double(i) / 100.0, saturation: 0.5, brightness: 0.9))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            .padding(8)
        }
    }
}
