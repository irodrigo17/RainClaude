# RainClaude

A single-page web app for tracking accumulated rainfall anywhere on the map.

## Project Structure

```
index.html      # Complete web app (HTML/CSS/JS, no build step)
manifest.json   # PWA manifest for Add to Home Screen
sw.js           # Service worker for offline caching
icon.svg        # App icon (rain cloud)
README.md       # Documentation
```

## Tech Stack

- **Single file:** All HTML, CSS, and JavaScript inline in `index.html`
- **No build step:** Open in browser or deploy to any static host
- **Leaflet** (CDN): Interactive map rendering and layer management
- **Open-Meteo API** (free, no key): Daily precipitation data
- **Photon/Komoot** (free, no key): Forward geocoding with proximity bias
- **Nominatim/OpenStreetMap**: Reverse geocoding
- **CARTO Voyager Tiles**: Base map layer
- **localStorage**: Persists saved places across reloads
- **PWA**: Service worker + manifest for iOS Add to Home Screen

## Features

- Place search with proximity bias, full-screen results page with infinite scroll
- Click-to-inspect, saved places with custom names
- Rainfall summary: 1d/2d/3d/7d totals + days since last rain
- Color-coded heatmap overlay with bilinear interpolation (12x8 grid upscaled to 180x120 canvas)
- Mobile responsive with bottom tab bar and iOS safe area support
- PWA: installable on iOS Home Screen for persistent storage and offline use
- IP-based geolocation to center map on user's area

## Running

Open `index.html` in a browser. No server required.
