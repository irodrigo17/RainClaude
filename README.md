# RainClaude

A single-page web app for tracking accumulated rainfall anywhere on the map. Search for places, save your favorites, and visualize precipitation with an interactive color-coded overlay.

## Features

- **Place search** -- Find any location using the search bar (powered by Photon/Komoot geocoding with proximity bias). Press Enter/Search for a full-screen results page with infinite scroll.
- **Click-to-inspect** -- Click anywhere on the map to get rainfall data for that point, with reverse geocoding to show the place name.
- **Saved places** -- Save locations to a persistent list in the sidebar. Each card shows accumulated rainfall at a glance. Saved places are stored in `localStorage` and survive page reloads. On iOS, add to Home Screen for durable persistent storage.
- **Custom names** -- Rename saved places with inline editing for quick identification.
- **Rainfall summary** -- For each location, see total precipitation over the last 1, 2, 3, and 7 days, plus how many days since the last rain.
- **Rainfall overlay** -- A color-coded heatmap rendered on the map showing precipitation intensity across the visible area. Includes a time period picker (1d/2d/3d/7d), opacity slider, and legend.
- **Mobile responsive** -- On narrow screens, a bottom tab bar switches between map and places views. iOS safe area insets are respected for notch/Dynamic Island devices.
- **PWA / Add to Home Screen** -- Includes a web app manifest, service worker, and Apple meta tags. Add to your iOS Home Screen for persistent storage, offline support, and a native app feel.
- **Auto-location** -- Map centers on your approximate location via IP geolocation on first load (when no saved places exist).

## Architecture

The app has no build step, no bundler, and no framework. HTML, CSS, and JavaScript are all inline in `index.html`, with a PWA manifest (`manifest.json`), service worker (`sw.js`), and icon (`icon.svg`) alongside it.

### External dependencies (loaded via CDN)

| Library | Purpose |
|---------|---------|
| [Leaflet](https://leafletjs.com/) | Interactive map rendering and layer management |

### APIs used (all free, no API keys required)

| API | Purpose |
|-----|---------|
| [Open-Meteo](https://open-meteo.com/) | Daily precipitation data. Used for both per-location rainfall summaries and the batch grid queries that power the map overlay. |
| [Photon](https://photon.komoot.io/) | Forward geocoding (place search) with proximity bias. Powered by Komoot, based on OpenStreetMap data. |
| [Nominatim](https://nominatim.openstreetmap.org/) | Reverse geocoding (click-to-name). Provided by OpenStreetMap. |
| [CARTO Voyager](https://carto.com/) | Base map tile layer. |
| [ipapi.co](https://ipapi.co/) | IP-based geolocation for initial map centering. |

### How the overlay works

When the map viewport changes, the app:

1. Divides the visible area into a 12x8 grid of sample points.
2. Fetches precipitation data for all 96 points in a single Open-Meteo API call (comma-separated coordinates).
3. Sums daily precipitation over the selected time window (1/2/3/7 days) for each grid point.
4. Renders a smooth heatmap by bilinearly interpolating the grid onto a 180x120 canvas.
5. Maps rainfall values to a color ramp (green -> yellow -> orange -> red -> purple) and displays it as a Leaflet `ImageOverlay`.

Updates are debounced (500ms after the user stops panning/zooming) and previous requests are aborted if the viewport changes again.

### Data flow

```
User interaction (search / click / pan)
        |
        v
  Photon API     ──>  Place search (forward geocoding)
  Nominatim API  ──>  Place name resolution (reverse geocoding)
        |
        v
  Open-Meteo API ──>  Daily precipitation_sum (past 7 days + today)
        |
        v
  Rendering
   ├── Sidebar cards: 1d/2d/3d/7d totals + days since last rain
   ├── Map popups: same data + save button
   ├── Map markers: color-coded circles for saved places
   └── Overlay: interpolated heatmap canvas
        |
        v
  localStorage  ──>  Persisted saved places (name, coords, cached data)
```

## Running locally

Open `index.html` in a browser. No server required.

## Deploying

This is a static site (4 files). Deploy to any static hosting provider:

- [Netlify Drop](https://app.netlify.com/drop) -- drag and drop, live in seconds
- [GitHub Pages](https://pages.github.com/) -- push to a repo, enable Pages
- [Cloudflare Pages](https://pages.cloudflare.com/) -- connect a repo or direct upload
- [Vercel](https://vercel.com/) -- connect a repo or `npx vercel`

## License

MIT
