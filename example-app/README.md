# Demo App (`example-app`)

This plugin includes an interactive example app located in the `example-app/` folder.

The app is built with HTML/CSS/JS and designed for **testing on real iOS devices** via Capacitor.

## Usage

```bash
cd example-app
npm install
npx cap sync
npx cap open ios
```

Then build and run the app on a physical iOS device using Xcode.

> ⚠️ Live Activities only work on real devices (not simulators or browsers).

## Features

- Interactive UI for testing Live Activities
- Prefilled demo data for each use case
- Real-time updates and alert testing
- Visual feedback via log console
- Each demo is isolated under `src/demos/{type}`

## Available Demos

| Type        | Description                        |
|-------------|------------------------------------|
| `custom`    | Generic key-value preview          |
| `delivery`  | Track delivery status + ETA        |
| `taxi`      | Show driver and live ride info     |
| `food`      | Display food order progress        |
| `eggtimer`  | Live countdown timer               |
| `workout`   | Track distance, duration, and pace |

Each demo provides its own HTML and JS file to simulate Live Activity creation, updates, and dismissal.

## Switching Layout

The `type` field in `attributes` (e.g. `"delivery"`) determines which SwiftUI layout is rendered in your widget extension.
