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

@AppScreenshot(.iPhone69Inch())
struct NavigationTitleDeviceViewScreenshot: View {
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

@AppScreenshot(.iPhone69Inch())
struct StatusBarDeviceViewScreenshot: View {
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
@AppScreenshot(.iPhone69Inch())
struct UIScreenDeviceViewScreenshot: View {
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
