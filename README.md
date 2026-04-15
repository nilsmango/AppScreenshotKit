# AppScreenshotKit

Generate App Store screenshots from SwiftUI views. Optionally render them inside Apple device frames.
Wrap your production views in `DeviceView` so screenshots stay in sync with your current UI.

> To use Apple device frames, download the bezel assets once (see [CLI](#cli)).

<details open>
<summary><b>Screenshots</b></summary>
<div align="center">
  <p>
    <img src="Demo/Screenshots/water/iPhone_6_9_inch/Phone08StatisticsOverview.png" width="22%" />
    <img src="Demo/Screenshots/en/iPad_13_inch/Pad04MIDIEdit.png" width="30%" />
    <img src="Demo/Screenshots/de/iPad_13_inch/Pad04MIDIEdit.png" width="30%" />
  </p>
  <p>
    <img src="Demo/Screenshots/ja/iPad_13_inch/Pad04MIDIEdit.png" width="30%" />
  </p>
</div>
</details>

## Quickstart

1. Add the package and products.

```swift
.package(url: "https://github.com/shitamori1272/AppScreenshotKit.git", from: "0.2.0"),
```

```swift
// In your target
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "AppScreenshotKit", package: "AppScreenshotKit")
    ]
)

// In your test target
.testTarget(
    name: "MyAppTests",
    dependencies: [
        .product(name: "AppScreenshotKitTestTools", package: "AppScreenshotKit")
    ]
)
```

2. (Optional) Download Apple device frames.

```bash
swift run AppScreenshotKitCLI download-bezel-image
```

3. Define a screenshot view.

Conform your struct to both `View` and `AppScreenshot`. Provide `configuration` and `body(environment:)`:

```swift
import AppScreenshotKit
import SwiftUI

struct LocaleDemo: View, AppScreenshot {
    nonisolated static var configuration: AppScreenshotConfiguration {
        AppScreenshotConfiguration(
            .iPhone69Inch(),
            options: .locale([Locale(identifier: "ja_JP"), Locale(identifier: "en_US")])
        )
    }

    @MainActor
    static func body(environment: AppScreenshotEnvironment) -> some View {
        Self().environment(\.appScreenshotEnvironment, environment)
    }

    @Environment(\.appScreenshotEnvironment) var environment

    var body: some View {
        VStack {
            Text("Locale Demo")
                .font(.system(size: 150, weight: .bold))

            DeviceView {
                DemoAppView()
            }
            .frame(height: environment.screenshotSize.height * 0.7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

The `body(environment:)` static method is always the same 3 lines — it creates an instance of your view and injects the screenshot environment.

<details>
<summary><b>Output</b></summary>
<div align="center">
  <img src="Demo/Screenshots/en_US/iPhone_6_9_inch/LocaleDemo.jpeg" width="45%" />
  <img src="Demo/Screenshots/ja_JP/iPhone_6_9_inch/LocaleDemo.jpeg" width="45%" />
</div>
</details>

4. Preview in Xcode.

```swift
#Preview {
    LocaleDemo.preview()
}
```

5. Export in tests (Swift Testing).

```swift
import AppScreenshotKitTestTools
import Foundation
import Testing

@Test @MainActor
func exportScreenshots() throws {
    let output = URL(fileURLWithPath: "/path/to/Screenshots")
    let exporter = AppScreenshotExporter(option: .file(outputURL: output))
    try exporter.export(LocaleDemo.self)
}
```

Run the test target on an iOS simulator.

## Rendering

Screenshots are captured using `UIWindowScene` + `drawHierarchy` on UIKit, which correctly renders glass effects, navigation bars, and system UI. When views are larger than the physical screen, they are scaled to fit and then resized to the target pixel dimensions.

## Setup Guide: Using in Your App

This guide shows how to integrate AppScreenshotKit into an Xcode app project. The recommended setup uses **two targets**:

### Target Structure

| Target | Type | Purpose |
|--------|------|---------|
| **MyApp Screenshots** | Regular (iOS) | Screenshot view definitions + previews |
| **MyAppScreenshotTests** | Unit Test (iOS) | Export test that renders and saves PNGs |

### Why Two Targets?

- The **Screenshots target** is a regular iOS target (not a test target). This lets you use Xcode previews for your screenshot views — you get instant visual feedback while designing.
- The **Export test target** is a unit test target. It runs your screenshot definitions through the full rendering pipeline and writes PNG files to disk. Run it on an iOS simulator to produce real App Store-ready images.

### Step 1: Add the Package

In Xcode: **File → Add Package Dependencies** → paste the package URL.

Then add the products to your targets:

- **MyApp Screenshots** target → add `AppScreenshotKit`
- **MyAppScreenshotTests** target → add `AppScreenshotKitTestTools`

Both targets should also depend on your main app target (so screenshot views can import your app's UI).

### Step 2: Create the Screenshots Target

Create a new **iOS → App** target (or a simple framework target) called something like `MyApp Screenshots`.

Create a shared options file:

```swift
// Screenshots/ScreenshotOptions.swift
#if os(iOS)
import AppScreenshotKit

let screenshotLocales: AppScreenshotConfiguration.Option = .locale([
    Locale(identifier: "en"),
    Locale(identifier: "de"),
    Locale(identifier: "ja"),
])
#endif
```

Define your screenshot views. Each one conforms to `View` + `AppScreenshot`:

```swift
// Screenshots/Phone01MainScreen.swift
#if os(iOS)
import AppScreenshotKit
import SwiftUI

struct Phone01MainScreen: View, AppScreenshot {
    nonisolated static var configuration: AppScreenshotConfiguration {
        AppScreenshotConfiguration(.iPhone69Inch(size: .w1290h2796), options: screenshotLocales)
    }

    @MainActor
    static func body(environment: AppScreenshotEnvironment) -> some View {
        Self().environment(\.appScreenshotEnvironment, environment)
    }

    @Environment(\.appScreenshotEnvironment) var environment

    var body: some View {
        VStack(spacing: 32) {
            Text("My App Title")
                .font(.system(size: 120, weight: .bold))

            DeviceView {
                MyMainScreenView()
            }
            .frame(height: environment.screenshotSize.height * 0.72)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    Phone01MainScreen.preview()
}
#endif
```

The `body(environment:)` implementation is always the same 3 lines — copy it into every screenshot struct. It creates an instance and injects the screenshot environment.

Use `#Preview` to get live Xcode previews of your marketing layout.

### Step 3: Create the Export Test Target

Create a new **iOS → Unit Testing Bundle** target called `MyAppScreenshotTests`.

It must depend on both `AppScreenshotKitTestTools` and your screenshots target:

```swift
// MyAppScreenshotTests/ExportScreenshots.swift
import AppScreenshotKitTestTools
import Foundation
import Testing
@testable import MyApp_Screenshots

@Test @MainActor
func exportScreenshots() throws {
    let output = URL(fileURLWithPath: "/path/to/App Store Metadata/Screenshots")
    let exporter = AppScreenshotExporter(option: .file(outputURL: output))

    try exporter.export(Phone01MainScreen.self)
    try exporter.export(Phone02Features.self)
    try exporter.export(Phone03Settings.self)
}
```

If a specific screenshot needs more time to render (complex views, async loading):

```swift
try exporter.export(Phone08Stats.self, captureDelay: 3.0)
```

### Step 4: Run the Export

1. Select the **MyAppScreenshotTests** scheme
2. Choose an **iOS simulator** as the destination
3. Run the test (Cmd+U)

PNGs are written to your output directory, organized by locale and device:

```
Screenshots/
├── en/
│   └── iPhone_6_9_inch/
│       ├── Phone01MainScreen.png
│       ├── Phone02Features.png
│       └── Phone03Settings.png
├── de/
│   └── iPhone_6_9_inch/
│       └── ...
└── ja/
    └── iPhone_6_9_inch/
        └── ...
```

### Tips

- **Iterate visually** with `#Preview` in the Screenshots target — no simulator needed
- **Export final images** by running the test target on simulator
- **Comment out lines** in the export test to re-export just one screenshot
- **Multiple locales** are generated automatically from your configuration options
- **iPad screenshots** use the same pattern — just add `.iPad130Inch()` to the configuration

## Customization

<details>
<summary><b>Devices, locales, tiles</b></summary>

- Add multiple devices or orientations.
- Generate per-locale screenshots.
- Create multi-tile walkthroughs.
- Export to files or attach to XCTest results.

Demo example (full source in `Demo/Sources/Demo/Demo.swift`):

```swift
struct READMEDemo: View, AppScreenshot {
    nonisolated static var configuration: AppScreenshotConfiguration {
        AppScreenshotConfiguration(.iPhone69Inch(), .iPad130Inch(), options: .tiles(4))
    }

    @MainActor
    static func body(environment: AppScreenshotEnvironment) -> some View {
        Self().environment(\.appScreenshotEnvironment, environment)
    }

    @Environment(\.appScreenshotEnvironment) var environment

    var body: some View {
        DeviceView { DemoAppView() }
    }
}
```

Output:

<div align="center">
  <p>
    <img src="Demo/Screenshots/en_JP/iPhone_6_9_inch/READMEDemo-0.jpeg" width="22%" />
    <img src="Demo/Screenshots/en_JP/iPhone_6_9_inch/READMEDemo-1.jpeg" width="22%" />
    <img src="Demo/Screenshots/en_JP/iPhone_6_9_inch/READMEDemo-2.jpeg" width="22%" />
    <img src="Demo/Screenshots/en_JP/iPhone_6_9_inch/READMEDemo-3.jpeg" width="22%" />
  </p>
  <p>
    <img src="Demo/Screenshots/en_JP/iPad_13_inch/READMEDemo-0.jpeg" width="45%" />
    <img src="Demo/Screenshots/en_JP/iPad_13_inch/READMEDemo-1.jpeg" width="45%" />
  </p>
  <p>
    <img src="Demo/Screenshots/en_JP/iPad_13_inch/READMEDemo-2.jpeg" width="45%" />
    <img src="Demo/Screenshots/en_JP/iPad_13_inch/READMEDemo-3.jpeg" width="45%" />
  </p>
</div>
</details>

## CLI

Download and register Apple bezel assets (required only if you want device frames).
The CLI fetches Apple’s official device images and stores them in the system cache (or your custom path) so exports can render frames.

```bash
swift run AppScreenshotKitCLI download-bezel-image
```

Custom output path:

```bash
swift run AppScreenshotKitCLI download-bezel-image --output /path/to/custom/location
```

Before using Apple’s marketing resources, review the [App Store marketing guidelines](https://developer.apple.com/app-store/marketing/guidelines/#section-products).

## Demo

<summary><b>Example project</b></summary>

- `Demo/Sources/Demo` contains screenshot definitions.
- `Demo/Tests/DemoTests` exports screenshots via `AppScreenshotExporter`.

Run `DemoTests` in Xcode to generate sample outputs under `Demo/Screenshots`.

## Requirements

- iOS 16+ / macOS 14+
- Swift 6 toolchain (Xcode 16+)

## License

MIT. See `LICENSE`.
