# RainClaude iOS

A native iOS app for tracking accumulated rainfall anywhere on the map. Search for outdoor places, save your favorites, and visualize precipitation with a smooth, interactive color-coded overlay.

## Features

- **Smooth rainfall overlay** -- Bitmap-rendered heatmap using per-pixel bilinear interpolation and Gaussian blur for smooth color gradients. Supports time period switching (1d/2d/3d/7d) and an opacity slider.
- **Place search** -- Search bar powered by `MKLocalSearch` with outdoor place prioritization (parks, forests, trails, campgrounds) via `MKLocalPointsOfInterestRequest`. Results are biased toward the current map viewport.
- **Click-to-inspect** -- Tap anywhere on the map to see rainfall data for that location.
- **Saved places** -- Save locations with custom names. Each saved place shows as an orange marker on the map.
- **Rainfall summary** -- For each location, see total precipitation over the last 1, 2, 3, and 7 days, plus days since last rain.

## Architecture

- **UI**: SwiftUI with MapKit (`Map`, `MapReader`, `MapProxy`)
- **Rainfall overlay**: Coarse ~8x8 grid fetched from Open-Meteo API, rendered as a `UIImage` with 8x per-pixel bilinear interpolation and `CIGaussianBlur`, positioned on the map via `MapProxy` coordinate conversion
- **Search**: Dual parallel search -- `MKLocalPointsOfInterestRequest` filtered to outdoor categories + general `MKLocalSearch.Request`, merged with outdoor results first
- **Color scale**: Continuous RGB interpolation between color stops (green -> yellow -> orange -> red -> purple) with pre-computed RGBA components for efficient bitmap rendering

## Building

```bash
xcodebuild -scheme RainClaude -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Or open `RainClaude.xcodeproj` in Xcode.

## APIs

| API | Purpose |
|-----|---------|
| [Open-Meteo](https://open-meteo.com/) | Daily precipitation data (free, no API key) |
| Apple MapKit | Map rendering, search, and geocoding |

## License

MIT
