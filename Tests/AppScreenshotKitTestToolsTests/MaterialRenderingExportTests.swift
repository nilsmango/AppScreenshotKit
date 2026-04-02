import AppScreenshotKit
import CoreGraphics
import ImageIO
import SwiftUI
import XCTest

@testable import AppScreenshotKitTestTools

final class MaterialRenderingExportTests: XCTestCase {
    @MainActor
    func testThinMaterialChangesExportedPixels() throws {
        let exporter = AppScreenshotExporter(
            option: .file(outputURL: FileManager.default.temporaryDirectory.appending(path: "MaterialExportTest"))
        )

        let withMaterial = try XCTUnwrap(exporter.export(ThinMaterialEnabledScreenshot.self).first)
        let withoutMaterial = try XCTUnwrap(exporter.export(ThinMaterialDisabledScreenshot.self).first)

        let difference = try meanAbsoluteChannelDifference(
            withMaterial.imageData,
            withoutMaterial.imageData,
            in: CGRect(x: 0.18, y: 0.34, width: 0.64, height: 0.32)
        )

        XCTAssertGreaterThan(
            difference,
            4,
            "Expected the exported pixels to change when .thinMaterial is applied."
        )
    }

    private func meanAbsoluteChannelDifference(
        _ lhsData: Data,
        _ rhsData: Data,
        in normalizedRect: CGRect
    ) throws -> Double {
        let lhsImage = try XCTUnwrap(cgImage(from: lhsData))
        let rhsImage = try XCTUnwrap(cgImage(from: rhsData))

        XCTAssertEqual(lhsImage.width, rhsImage.width)
        XCTAssertEqual(lhsImage.height, rhsImage.height)

        let width = lhsImage.width
        let height = lhsImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var lhsPixels = [UInt8](repeating: 0, count: height * bytesPerRow)
        var rhsPixels = [UInt8](repeating: 0, count: height * bytesPerRow)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard
            let lhsContext = CGContext(
                data: &lhsPixels,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            ),
            let rhsContext = CGContext(
                data: &rhsPixels,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            )
        else {
            XCTFail("Failed to create pixel contexts.")
            return 0
        }

        lhsContext.draw(lhsImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        rhsContext.draw(rhsImage, in: CGRect(x: 0, y: 0, width: width, height: height))

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

        var totalDifference: Double = 0
        var sampleCount = 0

        for y in yRange {
            for x in xRange {
                let offset = (y * bytesPerRow) + (x * bytesPerPixel)
                let red = abs(Int(lhsPixels[offset]) - Int(rhsPixels[offset]))
                let green = abs(Int(lhsPixels[offset + 1]) - Int(rhsPixels[offset + 1]))
                let blue = abs(Int(lhsPixels[offset + 2]) - Int(rhsPixels[offset + 2]))
                totalDifference += Double(red + green + blue) / 3.0
                sampleCount += 1
            }
        }

        return sampleCount > 0 ? totalDifference / Double(sampleCount) : 0
    }

    private func cgImage(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
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

@AppScreenshot(.iPhone69Inch())
private struct ThinMaterialEnabledScreenshot: View {
    var body: some View {
        DeviceView {
            ThinMaterialExportContent(includesMaterial: true)
                .preferredColorScheme(.dark)
        }
        .statusBarShown()
    }
}

@AppScreenshot(.iPhone69Inch())
private struct ThinMaterialDisabledScreenshot: View {
    var body: some View {
        DeviceView {
            ThinMaterialExportContent(includesMaterial: false)
                .preferredColorScheme(.dark)
        }
        .statusBarShown()
    }
}

private struct ThinMaterialExportContent: View {
    let includesMaterial: Bool

    var body: some View {
        ZStack {
            checkerboardBackground
            overlayCard
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var overlayCard: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.primary)
                .frame(width: 18, height: 18)

            VStack(alignment: .leading, spacing: 4) {
                Text("Material")
                    .font(.system(size: 18, weight: .semibold))
                Text("Export")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(width: 186)
        .background(
            includesMaterial ? AnyShapeStyle(.thinMaterial) : AnyShapeStyle(Color.clear),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }

    private var checkerboardBackground: some View {
        VStack(spacing: 0) {
            ForEach(0..<12, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<12, id: \.self) { col in
                        Rectangle()
                            .fill((row + col).isMultiple(of: 2) ? Color.black : Color.white)
                    }
                }
            }
        }
    }
}
