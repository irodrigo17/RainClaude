# RainClaude

A single-page web app for tracking accumulated rainfall anywhere on the map. Search for places, save your favorites, and visualize precipitation with an interactive color-coded overlay.

## Features

- **Place search** -- Find any location using the search bar (powered by Nominatim/OpenStreetMap geocoding). Click a result to fly to it on the map and see its rainfall data.
- **Click-to-inspect** -- Click anywhere on the map to get rainfall data for that point, with reverse geocoding to show the place name.
- **Saved places** -- Save locations to a persistent list in the sidebar. Each card shows accumulated rainfall at a glance. Saved places are stored in `localStorage` and survive page reloads.
- **Custom names** -- Rename saved places with inline editing for quick identification.
- **Rainfall summary** -- For each location, see total precipitation over the last 1, 2, 3, and 7 days, plus how many days since the last rain.
- **Rainfall overlay** -- A color-coded heatmap rendered on the map showing precipitation intensity across the visible area. Includes a time period picker (1d/2d/3d/7d), opacity slider, and legend.
- **Mobile responsive** -- On narrow screens, the saved places panel becomes a slide-out overlay toggled by a hamburger menu.

## Architecture

The entire app is a single `index.html` file with no build step, no bundler, and no framework. HTML, CSS, and JavaScript are all inline.

### External dependencies (loaded via CDN)

| Library | Purpose |
|---------|---------|
| [Leaflet](https://leafletjs.com/) | Interactive map rendering and layer management |

### APIs used (all free, no API keys required)

| API | Purpose |
|-----|---------|
| [Open-Meteo](https://open-meteo.com/) | Daily precipitation data. Used for both per-location rainfall summaries and the batch grid queries that power the map overlay. |
| [Nominatim](https://nominatim.openstreetmap.org/) | Forward geocoding (place search) and reverse geocoding (click-to-name). Provided by OpenStreetMap. |
| [OpenStreetMap Tiles](https://www.openstreetmap.org/) | Base map tile layer. |

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
  Nominatim API  ──>  Place name resolution
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

This is a static single-file site. Drop the file on any static hosting provider:

- [Netlify Drop](https://app.netlify.com/drop) -- drag and drop, live in seconds
- [GitHub Pages](https://pages.github.com/) -- push to a repo, enable Pages
- [Cloudflare Pages](https://pages.cloudflare.com/) -- connect a repo or direct upload
- [Vercel](https://vercel.com/) -- connect a repo or `npx vercel`

## License

MIT
