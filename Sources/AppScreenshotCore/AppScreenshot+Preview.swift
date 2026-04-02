//
//  File.swift
//  FocusForFun
//
//  Created by Shuhei Shitamori on 2025/04/25.
//

import Foundation
import SwiftUI

// MARK: - Preview Extension
extension AppScreenshot {
    /// Creates a preview of the screenshot for use in SwiftUI previews.
    ///
    /// This method provides a convenient way to preview how your App Store screenshots
    /// will look during development without generating the actual export files.
    ///
    /// - Returns: A SwiftUI view displaying the screenshot with its configured environment.
    @MainActor
    public static func preview(
        environmentPredicate: ((AppScreenshotEnvironment) -> Bool)? = nil
    )
        -> some View
    {
        var environments = configuration.environments()
        if let predicate = environmentPredicate {
            environments = environments.filter(predicate)
        }

        let canvasSpace: CGFloat = 50.0
        let previewPadding: CGFloat = 20.0

        let actualWidth = environments.map(\.canvasSize.width).max() ?? 0
        let actualHeight =
            environments.map(\.canvasSize.height).reduce(0, +) + (canvasSpace * CGFloat(environments.count - 1))

        return GeometryReader { proxy in
            let availableWidth = max(proxy.size.width - (previewPadding * 2), 1)
            let previewScale = min(availableWidth / actualWidth, 1)
            let scaledWidth = actualWidth * previewScale
            let scaledHeight = actualHeight * previewScale

            ScrollView {
                VStack(spacing: 0) {
                    PreviewLayout(preferredSize: CGSize(width: actualWidth, height: actualHeight)) {
                        VStack(spacing: canvasSpace) {
                            ForEach(environments, id: \.self) { environment in
                                previewScreenshotView(environment: environment)
                                    .overlay {
                                        if configuration.tileCount > 1 {
                                            VerticalLinesView(divisionCount: configuration.tileCount)
                                        }
                                    }
                            }
                        }
                    }
                    .scaleEffect(previewScale, anchor: .top)
                    .frame(width: scaledWidth, height: scaledHeight, alignment: .top)
                    .frame(maxWidth: .infinity, alignment: .top)
                    .padding(.horizontal, previewPadding)
                    .padding(.vertical, previewPadding)
                }
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.visible)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @MainActor
    @ViewBuilder
    private static func previewScreenshotView(environment: AppScreenshotEnvironment) -> some View {
        screenshotView(environment: environment)
    }
}

private struct PreviewLayout: Layout {

    let preferredSize: CGSize

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        preferredSize
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let subview = subviews.first else { return }
        subview.place(
            at: .init(x: bounds.midX, y: bounds.midY),
            anchor: .center,
            proposal: ProposedViewSize(preferredSize)
        )
    }
}
