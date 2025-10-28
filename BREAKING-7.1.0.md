# BREAKING.md — Version 7.1.0

> **🚨 ACTION REQUIRED — Widget build will fail unless you do this**
>
> The shared **`GenericAttributes.swift`** was **changed in v7.1.0**.  
> You **must re‑copy** the updated file into your **Widget Extension target**.  
> Skipping this step causes mismatched types at runtime and/or compile errors.

---

## What changed?

- The plugin’s shared `GenericAttributes` type (used by your widget) has been updated for push support and better initialization.
- Two JS APIs now return structured objects:
  - `isAvailable()` → **`{ value: boolean }`**
  - `isRunning({ id })` → **`{ value: boolean }`**

## Mandatory step — Re‑copy `GenericAttributes.swift`

1. In Xcode, open the **Pods**/Package tree for the plugin and locate the file:

```
Pods › CapacitorLiveActivity › LiveActivityPlugin › Shared › GenericAttributes.swift
```

> Depending on your dependency manager, the path may differ slightly. Look for the **Shared/GenericAttributes.swift** inside the plugin.

2. **Copy** `GenericAttributes.swift` into your **Widget Extension** target folder (e.g. `LiveActivityWidget/`).
   - In the dialog, **check** “Copy items if needed”.
   - Under _Add to targets_, **select your Widget Extension** (not only the App target).

3. Verify the file is a member of the **Widget Extension** target:
   - Select `GenericAttributes.swift` in the File Navigator → **File Inspector** (⌥⌘1) → **Target Membership** → ensure your **Widget Extension** is checked.

> Why? Xcode does **not** automatically include files from a plugin pod/package in your widget target.  
> The widget must compile with the **exact same** `GenericAttributes` type the app/plugin uses.

### How to confirm it worked

- **Build succeeds** without “cannot find type `GenericAttributes`” or ambiguous type errors.
- Your Live Activity renders on Lock Screen/Dynamic Island again.
- If you had runtime issues before, they disappear after re-copying.

### Common error symptoms if you skip this

- Compile error: `Cannot find type 'GenericAttributes' in scope` in your widget files
- Link/runtime mismatch (attributes/state shape not rendering as expected)
- Widget target builds against an **older** `GenericAttributes` and UI doesn’t update correctly

---

## API adjustments in 7.1.0

Update your boolean checks to read `.value`:

**Before**

```ts
if (await LiveActivity.isAvailable()) {
  /* ... */
}
if (await LiveActivity.isRunning({ id })) {
  /* ... */
}
```

**After**

```ts
if ((await LiveActivity.isAvailable()).value) {
  /* ... */
}
if ((await LiveActivity.isRunning({ id })).value) {
  /* ... */
}
```

Optional destructuring:

```ts
const { value: available } = await LiveActivity.isAvailable();
const { value: running } = await LiveActivity.isRunning({ id });
```

---

## New features in 7.1.0 (quick recap)

- `startActivityWithPush(...)` — start with `pushType: .token`; token arrives via `liveActivityPushToken` event
- `observePushToStartToken()` (iOS 17.2+) — stream global push‑to‑start token via `liveActivityPushToStartToken`
- `listActivities()` — discover activities (incl. those started via push)
- `liveActivityUpdate` event — lifecycle notifications: `active`, `stale`, `pending`, `ended`, `dismissed`

---

## iOS checklist (sanity)

- App **Info.plist** has:

```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

- **Capabilities** enabled on the App target:
  - **Push Notifications**
  - **Live Activities**
- The **Widget Extension** compiles and uses the copied **`GenericAttributes.swift`**

---

## Troubleshooting quick tips

- **Remote pushes not showing while the app is open?** That’s expected on iOS: remote Live‑Activity pushes are **not delivered in foreground**. Put the app in **background/terminated** to test remote start/update/end.
- If tokens do not appear:
  - Per‑activity token: ensure you used `startActivityWithPush(...)` and listen for `liveActivityPushToken`
  - Push‑to‑start token (iOS 17.2+): call `observePushToStartToken()` and listen for `liveActivityPushToStartToken`

---

## Reference commits

- `b46b200` — Push features & events (`startActivityWithPush`, `listActivities`, `observePushToStartToken`)
- `bd6c937` / `e15f91e` — Example server + structured returns (`isAvailable`, `isRunning`)
- `12f4ccf` — Tests updated and improved

---

**Need help?** Paste your error and your widget’s `LiveActivityWidget*.swift` snippet — we’ll map it to the exact fix.
