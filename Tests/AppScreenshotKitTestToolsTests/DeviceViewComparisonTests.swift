//
//  DeviceViewComparisonTests.swift
//  AppScreenshotKit
//
//  Visual comparison tests for DeviceView rendering.
//

import AppScreenshotKit
import SwiftUI
import XCTest

@testable import AppScreenshotKitTestTools

// MARK: - Side-by-Side Comparison Preview

/// Shows the same NavigationStack content rendered directly and inside DeviceView
/// side by side at the same size. If the navigation title positions match,
/// the DeviceView is rendering correctly.
///
/// Open this in Xcode Canvas to visually compare.
struct NavigationTitleComparisonPreview: View {
    var body: some View {
        HStack(spacing: 2) {
            VStack {
                Text("Direct (no DeviceView)")
                    .font(.caption2)
                    .padding(4)
                    .background(Color.yellow)
                sampleNavigationView
                    .frame(width: 402, height: 874)
                    .clipShape(RoundedRectangle(cornerRadius: 47.33))
            }

            VStack {
                Text("Inside DeviceView")
                    .font(.caption2)
                    .padding(4)
                    .background(Color.yellow)
                DeviceView {
                    sampleNavigationView
                }
                .statusBarShown()
            }
        }
        .padding()
    }

    private var sampleNavigationView: some View {
        NavigationStack {
            List {
                ForEach(0..<10) { i in
                    Text("Item \(i)")
                }
            }
            .navigationTitle("Test Title")
        }
    }
}

// MARK: - Status Bar Comparison Preview

struct StatusBarComparisonPreview: View {
    var body: some View {
        HStack(spacing: 2) {
            VStack {
                Text("Direct (no DeviceView)")
                    .font(.caption2)
                    .padding(4)
                    .background(Color.yellow)
                sampleStatusView
                    .frame(width: 402, height: 874)
                    .clipShape(RoundedRectangle(cornerRadius: 47.33))
            }

            VStack {
                Text("Inside DeviceView")
                    .font(.caption2)
                    .padding(4)
                    .background(Color.yellow)
                DeviceView {
                    sampleStatusView
                }
                .statusBarShown()
            }
        }
        .padding()
    }

    private var sampleStatusView: some View {
        ZStack(alignment: .top) {
            Color.white
            VStack {
                Spacer()
                Text("Content")
                    .font(.title)
                Spacer()
            }
        }
    }
}

// MARK: - UIScreen Comparison Preview

struct UIScreenComparisonPreview: View {
    var body: some View {
        HStack(spacing: 2) {
            VStack {
                Text("Direct (no DeviceView)")
                    .font(.caption2)
                    .padding(4)
                    .background(Color.yellow)
                sampleUIScreenView
                    .frame(width: 402, height: 874)
                    .clipShape(RoundedRectangle(cornerRadius: 47.33))
            }

            VStack {
                Text("Inside DeviceView")
                    .font(.caption2)
                    .padding(4)
                    .background(Color.yellow)
                DeviceView {
                    sampleUIScreenView
                }
            }
        }
        .padding()
    }

    private var sampleUIScreenView: some View {
        VStack(spacing: 20) {
            Spacer()
            #if canImport(UIKit)
                Text("UIScreen.main.bounds")
                    .font(.headline)
                Text("width: \(Int(UIScreen.main.bounds.size.width))")
                Text("height: \(Int(UIScreen.main.bounds.size.height))")
            #endif
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.blue.opacity(0.1))
    }
}

// MARK: - Export Comparison Tests

class DeviceViewComparisonTests: XCTestCase {

    /// Exports both versions side by side as a single image for easy visual comparison.
    @MainActor
    func testNavigationTitleComparisonExport() throws {
        let outputURL = FileManager.default.temporaryDirectory.appending(
            path: "NavTitleComparison"
        )
        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

        // Export with DeviceView
        let exporter = AppScreenshotExporter(option: .file(outputURL: outputURL))
        let outputs = try exporter.export(NavigationTitleDeviceViewScreenshot.self)
        XCTAssertFalse(outputs.isEmpty)
        for output in outputs {
            XCTAssertFalse(output.imageData.isEmpty)
        }

        // Save to a known location for manual inspection
        let savedPath = outputURL.path()
        print("[ComparisonTest] DeviceView navigation title screenshots saved to: \(savedPath)")
        if let files = try? FileManager.default.subpaths(atPath: savedPath) {
            for file in files {
                print("[ComparisonTest]   - \(file)")
            }
        }
    }

    @MainActor
    func testStatusBarComparisonExport() throws {
        let outputURL = FileManager.default.temporaryDirectory.appending(
            path: "StatusBarComparison"
        )
        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

        let exporter = AppScreenshotExporter(option: .file(outputURL: outputURL))
        let outputs = try exporter.export(StatusBarDeviceViewScreenshot.self)
        XCTAssertFalse(outputs.isEmpty)
        for output in outputs {
            XCTAssertFalse(output.imageData.isEmpty)
        }

        print("[ComparisonTest] StatusBar screenshots saved to: \(outputURL.path())")
    }

    @MainActor
    func testUIScreenBoundsIsDeviceSize() throws {
        let outputURL = FileManager.default.temporaryDirectory.appending(
            path: "UIScreenComparison"
        )
        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

        let exporter = AppScreenshotExporter(option: .file(outputURL: outputURL))
        let outputs = try exporter.export(UIScreenDeviceViewScreenshot.self)
        XCTAssertFalse(outputs.isEmpty)
        for output in outputs {
            XCTAssertFalse(output.imageData.isEmpty)
        }

        print("[ComparisonTest] UIScreen screenshots saved to: \(outputURL.path())")
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

@AppScreenshot(.iPhone69Inch())
struct UIScreenDeviceViewScreenshot: View {
    var body: some View {
        DeviceView {
            VStack(spacing: 20) {
                Spacer()
                #if canImport(UIKit)
                    Text("UIScreen.main.bounds")
                        .font(.headline)
                    Text("width: \(Int(UIScreen.main.bounds.size.width))")
                        .font(.title2)
                        .foregroundColor(
                            UIScreen.main.bounds.size.width == 402 ? .green : .red
                        )
                    Text("height: \(Int(UIScreen.main.bounds.size.height))")
                        .font(.title2)
                        .foregroundColor(
                            UIScreen.main.bounds.size.height == 874 ? .green : .red
                        )
                    Text("(expected 402 x 874)")
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
