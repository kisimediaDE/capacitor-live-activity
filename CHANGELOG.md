# Changelog

## [7.1.0] - 2025-10-28

### Added

- **Push-enabled Live Activities:** New `startActivityWithPush(...)` method to start a Live Activity with `pushType: .token`. The per-activity APNs/FCM live-activity token is emitted via the `'liveActivityPushToken'` event.
- **Global Push‑to‑Start (iOS 17.2+):**
  - `observePushToStartToken()` to stream the global push‑to‑start token.
  - `'liveActivityPushToStartToken'` event with the hex token payload.
- **Lifecycle Events:** New `'liveActivityUpdate'` listener that emits ActivityKit lifecycle changes (e.g., `active → stale → ended`).
- **Activity Discovery:** `listActivities()` to enumerate known `GenericAttributes` activities (useful after process restarts or when activities were started via push).
- **Example Server:** New `example-server/` using Firebase Admin SDK with endpoints for `/live-activity/start`, `/live-activity/update`, `/live-activity/end`, plus `/ping` for simple alerts.

### Changed

- **Typed boolean results:** `isAvailable()` and `isRunning({ id })` now resolve to structured objects: `{ value: boolean }` (aligns with native return shape).
- **Docs & Demos:** README and demo app updated; added **Push & Remote Start** demo page and improved logs & defaults.
- **Deps bump:** Updated toolchain & Capacitor:
  - `@capacitor/core` → ^7.4.4
  - `@capacitor/ios` → ^7.4.4
  - `vite` → ^7.1.12
  - `typescript` → ^5.9.3
  - `rollup` → ^4.52.5
  - `prettier-plugin-java` → ^2.7.7

### Fixed

- **Activity tracking on init:** The plugin now reloads active/stale/pending activities on startup and keeps its internal map in sync via `Activity.activityUpdates`, preventing stale state after process restarts.

### Breaking

- **Widget contract update – re‑copy required:** `GenericAttributes.swift` changed in 7.1.0. You **must re‑copy** this file into your **Live Activity widget target** in Xcode so the widget and plugin share the exact same `GenericAttributes` type.
  - In Xcode: _Pods → CapacitorLiveActivity → LiveActivityPlugin → Shared → GenericAttributes.swift_ → copy into your **Widget Extension** target (ensure “Copy items if needed” is checked).
- **API shape for booleans:** `isAvailable()` and `isRunning()` now return `{ value: boolean }`. Update call sites accordingly (see **Upgrade Notes**).

### Upgrade Notes

1. **Sync native platforms:**
   ```bash
   npx cap sync
   ```
2. **Re‑copy `GenericAttributes.swift` into your widget extension target** (overwriting the older copy).
3. **Update boolean checks in your code:**

   ```ts
   // OLD (pre‑7.1.0):
   // const available = await LiveActivity.isAvailable();
   // const running = await LiveActivity.isRunning({ id });

   // NEW (7.1.0+):
   const { value: available } = await LiveActivity.isAvailable();
   const { value: running } = await LiveActivity.isRunning({ id });
   ```

4. **Remote Start testing tip (iOS behavior):** Remote Live Activity pushes **are not delivered while your app is in the foreground**. Send the app to background or terminate it before testing push‑to‑start/update/end via FCM/APNs.

---

## [7.0.1] - 2025-07-08

### Added

- **Dismissal Policy Support:** Added optional `dismissalDate` parameter to `endActivity` to set a specific dismissal time for Live Activities. ([#1](https://github.com/kisimediaDE/capacitor-live-activity/pull/1) by [marciopinho](https://github.com/marciopinho))

### Changed

- **Moved `GenericAttributes.swift`:** Relocated `GenericAttributes.swift` to `ios/Sources/LiveActivityPlugin/Shared` to fix `verify:ios` build errors and ensure SwiftPM compatibility.
- **Updated DevDependencies:** Upgraded various devDependencies in `package.json`, including:
  - `@capacitor/core` → ^7.4.1
  - `@capacitor/ios` → ^7.4.1
  - `prettier` → ^3.6.2
  - `prettier-plugin-java` → ^2.7.1
  - `rollup` → ^4.44.2

### Fixed

- **Build Verification:** Resolved missing type errors by ensuring `GenericAttributes` is in the build target scope for iOS plugin verification.

---

### Upgrade Notes

No breaking changes. Ensure you run:

```bash
npx cap sync
```

## [7.0.0] - 2025-06-10

Initial release with full iOS Live Activities support.
