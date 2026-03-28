//
//  BezelImageLoader.swift
//  AppScreenshotKit
//
//  Created by Shuhei Shitamori on 2025/04/25.
//

import Foundation

struct BezelImageLoader {

    func imageData(_ device: AppScreenshotDevice, resourceBaseURL: URL) throws -> Data {
        let imageFileNameCandidates = imageFileNameCandidates(device)
        print("[BezelDebug] BezelImageLoader searching in: \(resourceBaseURL.path())")
        print("[BezelDebug] Looking for candidates: \(imageFileNameCandidates)")
        guard let filePaths = FileManager.default.subpaths(atPath: resourceBaseURL.path()) else {
            print("[BezelDebug] subpaths(atPath:) returned nil for: \(resourceBaseURL.path())")
            throw AppScreenshotKitError(
                message:
                    "No image file found: \(imageFileNameCandidates[0]) in \(resourceBaseURL.path())"
            )
        }
        print("[BezelDebug] Found \(filePaths.count) subpaths")
        if filePaths.isEmpty {
            print("[BezelDebug] No subpaths found in \(resourceBaseURL.path())")
        }
        guard let imageFilePath = filePaths.first(where: { path in
            imageFileNameCandidates.contains(where: { name in path.hasSuffix(name) })
        })
        else {
            throw AppScreenshotKitError(
                message:
                    "No image file found: \(imageFileNameCandidates[0]) in \(resourceBaseURL.path())"
            )
        }
        print("[BezelDebug] Found match: \(imageFilePath)")

        return try Data(contentsOf: resourceBaseURL.appendingPathComponent(imageFilePath))
    }

    private func imageFileNameCandidates(_ device: AppScreenshotDevice) -> [String] {
        let defaultDeviceName = device.model.rawValue

        let candidates =
            switch device.model {
            case .iPadPro11M4: ["iPad Pro 11(M4)"]
            case .iPadPro13M4: ["iPad Pro 13 (M4)"]
            case .iPadAir11M2: ["iPad Air 11 (M2)"]
            case .iPadAir13M2: ["iPad Air 13 (M2)"]
            default: []
            }
        return ([defaultDeviceName] + candidates)
            .map { "\($0) - \(device.color.rawValue) - \(device.orientation.rawValue).png" }
    }
}
