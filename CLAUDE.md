# RainClaude

A single-page web app for tracking accumulated rainfall anywhere on the map.

## Project Structure

```
index.html    # Complete web app (HTML/CSS/JS, no build step)
README.md     # Documentation
```

## Tech Stack

- **Single file:** All HTML, CSS, and JavaScript inline in `index.html`
- **No build step:** Open in browser or deploy to any static host
- **Leaflet** (CDN): Interactive map rendering and layer management
- **Open-Meteo API** (free, no key): Daily precipitation data
- **Nominatim/OpenStreetMap**: Forward/reverse geocoding
- **OpenStreetMap Tiles**: Base map layer
- **localStorage**: Persists saved places across reloads

## Features

- Place search, click-to-inspect, saved places with custom names
- Rainfall summary: 1d/2d/3d/7d totals + days since last rain
- Color-coded heatmap overlay with bilinear interpolation (12x8 grid upscaled to 180x120 canvas)
- Mobile responsive sidebar

## Running

Open `index.html` in a browser. No server required.
