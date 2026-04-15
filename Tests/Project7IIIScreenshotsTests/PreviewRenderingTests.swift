import Project7IIIScreenshots
import SwiftUI
import XCTest

@testable import Project7IIIScreenshotCore

#if canImport(UIKit)
    import UIKit

    final class PreviewRenderingTests: XCTestCase {
        @MainActor
        func testLandscapeSafeAreaInsetsIncludeLeadingAndTrailingEdges() {
            let insets = AppScreenshotDevice(
                orientation: .landscape,
                color: .blackTitanium,
                model: .iPhone16ProMax
            ).safeAreaInsets

            let uiInsets = uiEdgeInsets(from: insets)

            XCTAssertEqual(uiInsets.left, 62)
            XCTAssertEqual(uiInsets.right, 62)
            XCTAssertEqual(uiInsets.bottom, 21)
        }

        @MainActor
        func testPreviewKeepsUIScreenWidthDrivenHeaderVisibleAcrossLandscapeWidth() throws {
            let image = try renderedPreviewImage(of: PreviewUIScreenWidthScreenshot.preview())

            let blueCoverage = image.fractionOfPixels(
                matching: { rgba in
                    rgba.alpha > 200 && rgba.blue > 200 && rgba.red < 80 && rgba.green < 120
                },
                in: CGRect(x: 0.15, y: 0.18, width: 0.7, height: 0.08)
            )

            XCTAssertGreaterThan(
                blueCoverage,
                0.35,
                "Expected the UIScreen-sized header to remain visible across the landscape preview width."
            )
        }

        @MainActor
        func testPreviewKeepsLandscapeFooterVisibleAtBottom() throws {
            let image = try renderedPreviewImage(of: PreviewLandscapeFooterScreenshot.preview())

            let redCoverage = image.fractionOfPixels(
                matching: { rgba in
                    rgba.alpha > 200 && rgba.red > 200 && rgba.green < 80 && rgba.blue < 80
                },
                in: CGRect(x: 0.15, y: 0.82, width: 0.7, height: 0.1)
            )

            XCTAssertGreaterThan(
                redCoverage,
                0.15,
                "Expected the landscape footer buttons to remain visible in the preview output."
            )
        }

        @MainActor
        func testPreviewUsesScreenshotDeviceIdiomInsteadOfOuterPreviewDevice() throws {
            let image = try renderedPreviewImage(of: PreviewIdiomScreenshot.preview())

            let redCoverage = image.fractionOfPixels(
                matching: { rgba in
                    rgba.alpha > 200 && rgba.red > 200 && rgba.green < 80 && rgba.blue < 80
                },
                in: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
            )

            XCTAssertGreaterThan(
                redCoverage,
                0.4,
                "Expected iPhone screenshot previews to report `.phone` for UIDevice.current.userInterfaceIdiom."
            )
        }

        @MainActor
        private func renderedPreviewImage<Content: View>(of view: Content) throws -> UIImage {
            let data = try PNGDataConverter().convert(view)
            return try XCTUnwrap(UIImage(data: data))
        }
    }

    private struct PreviewUIScreenWidthScreenshot: View, AppScreenshot {
        nonisolated static var configuration: AppScreenshotConfiguration {
            .init(
                .iPhone69Inch(
                    model: .iPhone16Plus(orientation: .landscape),
                    size: .w2796h1290
                )
            )
        }

        @MainActor
        static func body(environment: AppScreenshotEnvironment) -> some View {
            Self().environment(\.appScreenshotEnvironment, environment)
        }

        var body: some View {
            DeviceView {
                VStack(spacing: 0) {
                    Color.blue
                        .frame(width: UIScreen.main.bounds.width, height: 96)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
            }
        }
    }

    private struct PreviewLandscapeFooterScreenshot: View, AppScreenshot {
        nonisolated static var configuration: AppScreenshotConfiguration {
            .init(
                .iPhone69Inch(
                    model: .iPhone16Plus(orientation: .landscape),
                    size: .w2796h1290
                )
            )
        }

        @MainActor
        static func body(environment: AppScreenshotEnvironment) -> some View {
            Self().environment(\.appScreenshotEnvironment, environment)
        }

        var body: some View {
            DeviceView {
                VStack(spacing: 0) {
                    Color.white
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.red)
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.red)
                    }
                    .frame(height: 94)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private struct PreviewIdiomScreenshot: View, AppScreenshot {
        nonisolated static var configuration: AppScreenshotConfiguration {
            .init(
                .iPhone69Inch(
                    model: .iPhone16Plus(orientation: .portrait),
                    size: .w1290h2796
                )
            )
        }

        @MainActor
        static func body(environment: AppScreenshotEnvironment) -> some View {
            Self().environment(\.appScreenshotEnvironment, environment)
        }

        var body: some View {
            DeviceView {
                Group {
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        Color.red
                    } else {
                        Color.blue
                    }
                }
            }
        }
    }

    private extension UIImage {
        struct RGBA {
            let red: UInt8
            let green: UInt8
            let blue: UInt8
            let alpha: UInt8
        }

        func fractionOfPixels(
            matching predicate: (RGBA) -> Bool,
            in normalizedRect: CGRect
        ) -> Double {
            guard let cgImage else { return 0 }

            let width = cgImage.width
            let height = cgImage.height
            let bytesPerPixel = 4
            let bytesPerRow = bytesPerPixel * width
            var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)

            guard let context = CGContext(
                data: &pixels,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                return 0
            }

            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

            let xRange = normalizedPixelRange(
                origin: normalizedRect.minX,
                length: normalizedRect.width,
                limit: width
            )
            let yRange = normalizedPixelRange(
                origin: normalizedRect.minY,
                length: normalizedRect.height,
                limit: height
            )

            var matches = 0
            var total = 0

            for y in yRange {
                for x in xRange {
                    let offset = (y * bytesPerRow) + (x * bytesPerPixel)
                    let rgba = RGBA(
                        red: pixels[offset],
                        green: pixels[offset + 1],
                        blue: pixels[offset + 2],
                        alpha: pixels[offset + 3]
                    )
                    total += 1
                    if predicate(rgba) {
                        matches += 1
                    }
                }
            }

            guard total > 0 else { return 0 }
            return Double(matches) / Double(total)
        }

        private func normalizedPixelRange(origin: CGFloat, length: CGFloat, limit: Int) -> Range<Int> {
            let lowerBound = max(0, min(limit - 1, Int(CGFloat(limit) * origin)))
            let upperBound = max(
                lowerBound + 1,
                min(limit, Int(CGFloat(limit) * (origin + length)))
            )
            return lowerBound..<upperBound
        }
    }
#endif
