# Capacitor Live Activity – Example Server

Minimal Node/TS server to send **Live Activity** pushes via **Firebase Cloud Messaging** (FCM HTTP v1).

## Requirements

- Node 18+
- Firebase Admin SDK **>= 13.5.0** (supports `apns.liveActivityToken`)
- A Firebase project with **APNs key** configured
- On-device iOS 17.2+ for **remote start** (push-to-start)
- Your app must collect:
  - **FCM registration token** (per device)
  - **Live Activity push token** (per activity) or **push-to-start token** (global) from ActivityKit/your plugin

## Setup

```bash
cp .env.example .env
# set GOOGLE_APPLICATION_CREDENTIALS to your service account JSON
npm i
npm run dev
```
