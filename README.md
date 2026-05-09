# SKYWATCH ATC — Defense Grade Flight Radar

A real-time interactive flight radar application built with Flutter, featuring a defense industry (QT-style) dark tactical UI/UX.

## Features

- **Live Flight Tracking** — Real-time data from [OpenSky Network](https://opensky-network.org/) API (free, no key required)
- **Interactive Map** — Dark tactical map with CartoDB Dark tiles
- **Radar Sweep Animation** — Rotating radar sweep overlay with range rings and azimuth lines
- **HUD Interface** — Military-grade heads-up display with corner brackets and panel labels
- **Flight Details** — Heading compass, telemetry data (altitude, speed, vertical rate), threat assessment
- **Contact List** — Searchable and filterable flight list with status indicators
- **Auto-Refresh** — Automatic 30-second data refresh cycle

## UI Design

The interface follows defense industry / air traffic control conventions:

- **Color Palette**: Deep navy background, cyan primary, green accent, amber warning, red alert
- **Typography**: Monospace font with wide letter-spacing for readability
- **Layout**: Three-panel layout (contact list | radar map | target data)
- **Overlays**: Grid overlay, radar sweep, range rings, azimuth lines
- **Status Bar**: UTC clock, live status, tracked aircraft counts

## Data Source

Uses the **OpenSky Network REST API**:
- Endpoint: `https://opensky-network.org/api/states/all`
- No API key required for anonymous access (rate limited to ~10 req/min)
- Data: ICAO24, callsign, country, position, altitude, speed, heading, vertical rate

## Getting Started

```bash
flutter pub get
flutter run
```

Recommended platforms: **Desktop (Windows/macOS/Linux)** or **Web** for the best widescreen experience.

## Dependencies

- `flutter_map` — Interactive map widget
- `latlong2` — Geographic coordinate types
- `http` — HTTP client for OpenSky API
- `provider` — State management
- `intl` — Date/time formatting
