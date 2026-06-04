# 📡 capacitor-live-activity

[![npm](https://img.shields.io/npm/v/capacitor-live-activity)](https://www.npmjs.com/package/capacitor-live-activity)
[![bundle size](https://img.shields.io/bundlephobia/minzip/capacitor-live-activity)](https://bundlephobia.com/result?p=capacitor-live-activity)
[![License: MIT](https://img.shields.io/npm/l/capacitor-live-activity)](./LICENSE)
[![Platforms](https://img.shields.io/badge/platforms-iOS-orange)](#-platform-behavior)
[![Capacitor](https://img.shields.io/badge/capacitor-8.x-blue)](https://capacitorjs.com/)

A Capacitor plugin for managing iOS Live Activities using ActivityKit and Swift.

> [!TIP]
> 🚀 Looking for a ready-to-run demo? → [Try the Example App](./example-app/)

## 🧭 Table of contents

- [📡 capacitor-live-activity](#-capacitor-live-activity)
  - [🧭 Table of contents](#-table-of-contents)
  - [📦 Install](#-install)
  - [🧩 Widget Setup (Required)](#-widget-setup-required)
    - [1. Add a Widget Extension in Xcode](#1-add-a-widget-extension-in-xcode)
    - [2. Configure the Widget (Example)](#2-configure-the-widget-example)
    - [3. Add GenericAttributes.swift to your Widget Target](#3-add-genericattributesswift-to-your-widget-target)
      - [To make it available in your widget extension:](#to-make-it-available-in-your-widget-extension)
      - [Why is this needed?](#why-is-this-needed)
    - [4. Add Capability](#4-add-capability)
    - [5. Ensure Inclusion in Build](#5-ensure-inclusion-in-build)
  - [🧠 Platform behavior](#-platform-behavior)
  - [💡 Usage Examples](#-usage-examples)
    - [Basic Live Activity](#basic-live-activity)
    - [Scheduled Live Activity (iOS 26+)](#scheduled-live-activity-ios-26)
  - [📱 Example App](#-example-app)
  - [🛠 API](#-api)
    - [startActivity(...)](#startactivity)
    - [startActivityWithPush(...)](#startactivitywithpush)
    - [startActivityScheduled(...)](#startactivityscheduled)
    - [updateActivity(...)](#updateactivity)
    - [endActivity(...)](#endactivity)
    - [isAvailable()](#isavailable)
    - [isRunning(...)](#isrunning)
    - [getCurrentActivity(...)](#getcurrentactivity)
    - [listActivities()](#listactivities)
    - [observePushToStartToken()](#observepushtostarttoken)
    - [addListener('liveActivityPushToken', ...)](#addlistenerliveactivitypushtoken-)
    - [addListener('liveActivityPushToStartToken', ...)](#addlistenerliveactivitypushtostarttoken-)
    - [addListener('liveActivityUpdate', ...)](#addlistenerliveactivityupdate-)
    - [Interfaces](#interfaces)
      - [StartActivityOptions](#startactivityoptions)
      - [ScheduledActivityOptions](#scheduledactivityoptions)
      - [AlertConfiguration](#alertconfiguration)
      - [UpdateActivityOptions](#updateactivityoptions)
      - [EndActivityOptions](#endactivityoptions)
      - [LiveActivityState](#liveactivitystate)
      - [ListActivitiesResult](#listactivitiesresult)
      - [Array](#array)
      - [ConcatArray](#concatarray)
      - [PluginListenerHandle](#pluginlistenerhandle)
      - [PushTokenEvent](#pushtokenevent)
      - [PushToStartTokenEvent](#pushtostarttokenevent)
      - [ActivityUpdateEvent](#activityupdateevent)
    - [Type Aliases](#type-aliases)
      - [Record](#record)

## 📦 Install

```bash
npm install capacitor-live-activity
npx cap sync
```

> [!NOTE]
> This plugin requires **iOS 16.2+** to work properly due to `ActivityKit` API usage.

> [!IMPORTANT]
> This plugin **requires a Live Activity widget extension** to be present and configured in your Xcode project.  
> Without a widget, Live Activities will not appear on the lock screen or Dynamic Island.

## 🧩 Widget Setup (Required)

To use Live Activities, your app must include a widget extension that defines the UI for the Live Activity using ActivityKit. Without this, the Live Activity will not appear on the Lock Screen or Dynamic Island.

### 1. Add a Widget Extension in Xcode

1.  Open your app’s iOS project in Xcode.
2.  Go to File > New > Target…
3.  Choose Widget Extension.
4.  Name it e.g. LiveActivityWidget.
5.  Check the box “Include Live Activity”.
6.  Finish and wait for Xcode to generate the files.

### 2. Configure the Widget (Example)

Make sure the widget uses the same attribute type as the plugin (e.g. GenericAttributes.swift):

```swift
import ActivityKit
import WidgetKit
import SwiftUI

struct LiveActivityWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GenericAttributes.self) { context in
            // Lock Screen UI
            VStack {
                Text(context.state.values["title"] ?? "⏱")
                Text(context.state.values["status"] ?? "-")
            }
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.values["title"] ?? "")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.values["status"] ?? "")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.values["message"] ?? "")
                }
            } compactLeading: {
                Text("🔔")
            } compactTrailing: {
                Text(context.state.values["status"] ?? "")
            } minimal: {
                Text("🎯")
            }
        }
    }
}
```

### 3. Add GenericAttributes.swift to your Widget Target

To support Live Activities with dynamic values, this plugin uses a shared Swift struct called GenericAttributes.

> By default, it’s located under: Pods > CapacitorLiveActivity > LiveActivityPlugin > Shared > GenericAttributes.swift

#### To make it available in your widget extension:

1. Open Xcode and go to the File Navigator.
2. Expand Pods > CapacitorLiveActivity > Shared.
3. Copy GenericAttributes.swift to Widget Extension Target, e.g. LiveActivityWidget
4. Make sure to select "Copy files to destination"

#### Why is this needed?

Xcode doesn’t automatically include files from a CocoaPods plugin into your widget target.
Without this step, your widget won’t compile because it cannot find GenericAttributes.

### 4. Add Capability

Go to your main app target → Signing & Capabilities tab and add:

- Background Modes → Background fetch
- Go to your app target → Signing & Capabilities:
  - ✅ Push Notifications
  - ✅ Live Activities

### 5. Ensure Inclusion in Build

- In your **App target’s Info.plist**, ensure:

```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

- Clean and rebuild the project (Cmd + Shift + K, then Cmd + B).

## 🧠 Platform behavior

- iOS 16.2+: Live Activities (local start/update/end)
- iOS 17.2+: Remote start via push (push-to-start) and per-activity push updates
- iOS 26.0+: Schedule Live Activities to start at a future date
- Real device required (no Simulator)
- For remote flows, test with the app in background/terminated

## 💡 Usage Examples

### Basic Live Activity

```typescript
import { LiveActivity } from 'capacitor-live-activity';

// Start a basic Live Activity
await LiveActivity.startActivity({
  id: 'my-activity',
  attributes: {
    title: 'Delivery',
  },
  contentState: {
    status: 'On the way',
    eta: '15 min',
  },
});

// Update it
await LiveActivity.updateActivity({
  id: 'my-activity',
  contentState: {
    status: 'Almost there!',
    eta: '2 min',
  },
});

// End it
await LiveActivity.endActivity({
  id: 'my-activity',
  contentState: {
    status: 'Delivered',
    eta: '0 min',
  },
});
```

### Scheduled Live Activity (iOS 26+)

Schedule a Live Activity to start at a future date, perfect for upcoming events like sports games, meetings, or deliveries:

```typescript
import { LiveActivity } from 'capacitor-live-activity';

// Schedule a Live Activity to start in 2 hours
const futureDate = Date.now() / 1000 + 2 * 60 * 60; // UNIX timestamp in seconds

await LiveActivity.startActivityScheduled({
  id: 'game-activity',
  attributes: {
    homeTeam: 'Warriors',
    awayTeam: 'Lakers',
  },
  contentState: {
    status: 'Scheduled',
    startTime: '7:30 PM',
  },
  startDate: futureDate,
  alertConfiguration: {
    title: 'Game Starting Soon!',
    body: 'Warriors vs Lakers begins in 15 minutes',
    sound: 'default',
  },
  enablePushToUpdate: true, // Optional: enable push updates
  style: 'standard', // Optional: 'standard' or 'transient'
});

// The activity will automatically start at the scheduled time
// Listen for push tokens if enablePushToUpdate is true
LiveActivity.addListener('liveActivityPushToken', (event) => {
  console.log('Push token:', event.token);
  // Send this token to your server for push updates
});
```

### Native Update Token Registration

Configure a backend endpoint once before starting push-enabled Live Activities. iOS persists this setting and will POST each per-activity update token natively while still emitting the existing `liveActivityPushToken` event.

```typescript
await LiveActivity.setUpdateTokenEndpoint({
  url: 'https://api.example.com/live-activity/register-token',
  headers: {
    Authorization: 'Bearer <token>',
  },
});

await LiveActivity.startActivityWithPush({
  id: 'delivery-123',
  attributes: { type: 'delivery' },
  contentState: { status: 'Preparing' },
});
```

The endpoint receives:

```json
{
  "id": "delivery-123",
  "activityId": "system-activity-id",
  "token": "hex-encoded-live-activity-token"
}
```

## 📱 Example App

This plugin includes a fully functional demo app under the [`example-app/`](./example-app) directory.

The demo is designed to run on real iOS devices and showcases multiple Live Activity types like delivery, timer, taxi, workout, and more.

- Launch and test various Live Activities interactively
- Trigger updates and alert banners
- View JSON state changes in a live log console

> [!NOTE]
> For full instructions, see [example-app/README.md](./example-app/README.md)

## 🛠 API

<docgen-index>

* [`startActivity(...)`](#startactivity)
* [`startActivityWithPush(...)`](#startactivitywithpush)
* [`startActivityScheduled(...)`](#startactivityscheduled)
* [`updateActivity(...)`](#updateactivity)
* [`endActivity(...)`](#endactivity)
* [`isAvailable()`](#isavailable)
* [`isRunning(...)`](#isrunning)
* [`getCurrentActivity(...)`](#getcurrentactivity)
* [`listActivities()`](#listactivities)
* [`observePushToStartToken()`](#observepushtostarttoken)
* [`setUpdateTokenEndpoint(...)`](#setupdatetokenendpoint)
* [`addListener('liveActivityPushToken', ...)`](#addlistenerliveactivitypushtoken-)
* [`addListener('liveActivityPushToStartToken', ...)`](#addlistenerliveactivitypushtostarttoken-)
* [`addListener('liveActivityUpdate', ...)`](#addlistenerliveactivityupdate-)
* [Interfaces](#interfaces)
* [Type Aliases](#type-aliases)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### startActivity(...)

```typescript
startActivity(options: StartActivityOptions) => Promise<void>
```

Start a new Live Activity with local (on-device) ActivityKit.

| Param         | Type                                                                  |
| ------------- | --------------------------------------------------------------------- |
| **`options`** | <code><a href="#startactivityoptions">StartActivityOptions</a></code> |

**Since:** 0.0.1

--------------------


### startActivityWithPush(...)

```typescript
startActivityWithPush(options: StartActivityOptions) => Promise<{ activityId: string; }>
```

Start a new Live Activity locally **with push support** (`pushType: .token`).

The per-activity APNs/FCM live-activity token will be emitted via
the `"liveActivityPushToken"` event shortly after starting.

| Param         | Type                                                                  |
| ------------- | --------------------------------------------------------------------- |
| **`options`** | <code><a href="#startactivityoptions">StartActivityOptions</a></code> |

**Returns:** <code>Promise&lt;{ activityId: string; }&gt;</code>

**Since:** 7.1.0

--------------------


### startActivityScheduled(...)

```typescript
startActivityScheduled(options: ScheduledActivityOptions) => Promise<{ activityId: string; }>
```

Schedule a new Live Activity to start at a future date (iOS 26+).

The activity will start at the specified date even if the app is in the background.
An alert configuration is required to notify the user when the activity starts.

Note: Scheduled activities count towards the system limit for simultaneous Live Activities.
The activity state will be `pending` until the scheduled start time.

| Param         | Type                                                                          |
| ------------- | ----------------------------------------------------------------------------- |
| **`options`** | <code><a href="#scheduledactivityoptions">ScheduledActivityOptions</a></code> |

**Returns:** <code>Promise&lt;{ activityId: string; }&gt;</code>

**Since:** 8.1.0

--------------------


### updateActivity(...)

```typescript
updateActivity(options: UpdateActivityOptions) => Promise<void>
```

Update an existing Live Activity (identified by your logical `id`).

| Param         | Type                                                                    |
| ------------- | ----------------------------------------------------------------------- |
| **`options`** | <code><a href="#updateactivityoptions">UpdateActivityOptions</a></code> |

**Since:** 0.0.1

--------------------


### endActivity(...)

```typescript
endActivity(options: EndActivityOptions) => Promise<void>
```

End an existing Live Activity (identified by your logical `id`).

Optionally provide a final state and a dismissal policy.

| Param         | Type                                                              |
| ------------- | ----------------------------------------------------------------- |
| **`options`** | <code><a href="#endactivityoptions">EndActivityOptions</a></code> |

**Since:** 0.0.1

--------------------


### isAvailable()

```typescript
isAvailable() => Promise<{ value: boolean; }>
```

Return whether Live Activities are enabled and allowed on this device.

**Note:** This method resolves to `{ value: boolean }` to match native.

**Returns:** <code>Promise&lt;{ value: boolean; }&gt;</code>

**Since:** 0.0.1

--------------------


### isRunning(...)

```typescript
isRunning(options: { id: string; }) => Promise<{ value: boolean; }>
```

Return whether a Live Activity with the given logical `id` is currently running.

**Note:** This method resolves to `{ value: boolean }` to match native.

| Param         | Type                         |
| ------------- | ---------------------------- |
| **`options`** | <code>{ id: string; }</code> |

**Returns:** <code>Promise&lt;{ value: boolean; }&gt;</code>

**Since:** 0.0.1

--------------------


### getCurrentActivity(...)

```typescript
getCurrentActivity(options?: { id?: string | undefined; } | undefined) => Promise<LiveActivityState | undefined>
```

Get the current Live Activity state.

If an `id` is provided, returns that specific activity.
If no `id` is given, returns the most recently started activity.

| Param         | Type                          |
| ------------- | ----------------------------- |
| **`options`** | <code>{ id?: string; }</code> |

**Returns:** <code>Promise&lt;<a href="#liveactivitystate">LiveActivityState</a>&gt;</code>

**Since:** 0.0.1

--------------------


### listActivities()

```typescript
listActivities() => Promise<ListActivitiesResult>
```

List known activities (ActivityKit `active`/`stale`/`pending` etc.)
for the shared `GenericAttributes` type.

Useful to discover activities that were started via push once the process
becomes aware of them.

**Returns:** <code>Promise&lt;<a href="#listactivitiesresult">ListActivitiesResult</a>&gt;</code>

**Since:** 7.1.0

--------------------


### observePushToStartToken()

```typescript
observePushToStartToken() => Promise<void>
```

iOS 17.2+: begin streaming the global **push-to-start** token.

The token will be emitted via `"liveActivityPushToStartToken"`.

**Since:** 7.1.0

--------------------


### setUpdateTokenEndpoint(...)

```typescript
setUpdateTokenEndpoint(options: UpdateTokenEndpointOptions) => Promise<void>
```

Configure a native endpoint that receives per-activity update tokens.

When a `liveActivityPushToken` is received, the iOS plugin will keep emitting
the existing event and additionally POST `{ id, activityId, token }` to this
endpoint. The endpoint is persisted on iOS so token registration can continue
across app launches. Network errors are logged natively and do not reject
`startActivityWithPush`.

| Param         | Type                                                                              |
| ------------- | --------------------------------------------------------------------------------- |
| **`options`** | <code><a href="#updatetokenendpointoptions">UpdateTokenEndpointOptions</a></code> |

**Since:** 8.2.0

--------------------


### addListener('liveActivityPushToken', ...)

```typescript
addListener(eventName: 'liveActivityPushToken', listenerFunc: (event: PushTokenEvent) => void) => Promise<PluginListenerHandle>
```

Emitted when a per-activity live-activity push token becomes available
after calling `startActivityWithPush`.

| Param              | Type                                                                          |
| ------------------ | ----------------------------------------------------------------------------- |
| **`eventName`**    | <code>'liveActivityPushToken'</code>                                          |
| **`listenerFunc`** | <code>(event: <a href="#pushtokenevent">PushTokenEvent</a>) =&gt; void</code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

**Since:** 7.1.0

--------------------


### addListener('liveActivityPushToStartToken', ...)

```typescript
addListener(eventName: 'liveActivityPushToStartToken', listenerFunc: (event: PushToStartTokenEvent) => void) => Promise<PluginListenerHandle>
```

Emitted when a global **push-to-start** token is available (iOS 17.2+).

| Param              | Type                                                                                        |
| ------------------ | ------------------------------------------------------------------------------------------- |
| **`eventName`**    | <code>'liveActivityPushToStartToken'</code>                                                 |
| **`listenerFunc`** | <code>(event: <a href="#pushtostarttokenevent">PushToStartTokenEvent</a>) =&gt; void</code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

**Since:** 7.1.0

--------------------


### addListener('liveActivityUpdate', ...)

```typescript
addListener(eventName: 'liveActivityUpdate', listenerFunc: (event: ActivityUpdateEvent) => void) => Promise<PluginListenerHandle>
```

Emitted when the lifecycle of a Live Activity changes (e.g. active → stale).

| Param              | Type                                                                                    |
| ------------------ | --------------------------------------------------------------------------------------- |
| **`eventName`**    | <code>'liveActivityUpdate'</code>                                                       |
| **`listenerFunc`** | <code>(event: <a href="#activityupdateevent">ActivityUpdateEvent</a>) =&gt; void</code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

**Since:** 7.1.0

--------------------


### Interfaces


#### StartActivityOptions

Options for starting a Live Activity.

| Prop               | Type                                                            | Description                                           |
| ------------------ | --------------------------------------------------------------- | ----------------------------------------------------- |
| **`id`**           | <code>string</code>                                             | Logical identifier you use to reference the activity. |
| **`attributes`**   | <code><a href="#record">Record</a>&lt;string, string&gt;</code> | Immutable attributes for the activity.                |
| **`contentState`** | <code><a href="#record">Record</a>&lt;string, string&gt;</code> | Initial dynamic content state.                        |
| **`timestamp`**    | <code>number</code>                                             | Optional UNIX timestamp when the activity started.    |


#### ScheduledActivityOptions

Options for scheduling a Live Activity to start at a future date (iOS 26+).

| Prop                     | Type                                                              | Description                                                                                                                                                                                                             | Default                 |
| ------------------------ | ----------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------- |
| **`id`**                 | <code>string</code>                                               | Logical identifier you use to reference the activity.                                                                                                                                                                   |                         |
| **`attributes`**         | <code><a href="#record">Record</a>&lt;string, string&gt;</code>   | Immutable attributes for the activity.                                                                                                                                                                                  |                         |
| **`contentState`**       | <code><a href="#record">Record</a>&lt;string, string&gt;</code>   | Initial dynamic content state.                                                                                                                                                                                          |                         |
| **`startDate`**          | <code>number</code>                                               | UNIX timestamp (in seconds) when the Live Activity should start. Must be in the future. The system will start the activity at this time even if the app is in the background.                                           |                         |
| **`alertConfiguration`** | <code><a href="#alertconfiguration">AlertConfiguration</a></code> | Alert configuration to notify the user when the activity starts. Required for scheduled activities to inform users about the started Live Activity.                                                                     |                         |
| **`enablePushToUpdate`** | <code>boolean</code>                                              | Whether to enable push notifications for this activity. If true, the activity will receive push token updates via the `liveActivityPushToken` event.                                                                    | <code>false</code>      |
| **`style`**              | <code>'standard' \| 'transient'</code>                            | Activity style: 'standard' or 'transient'. - 'standard': Activity continues until explicitly ended or max duration reached. - 'transient': Activity appears in Dynamic Island but ends automatically when device locks. | <code>'standard'</code> |


#### AlertConfiguration

Alert configuration shown for certain updates.

| Prop        | Type                | Description                            |
| ----------- | ------------------- | -------------------------------------- |
| **`title`** | <code>string</code> | Optional title of the alert.           |
| **`body`**  | <code>string</code> | Optional body text of the alert.       |
| **`sound`** | <code>string</code> | Optional sound file name or "default". |


#### UpdateActivityOptions

Options for updating a Live Activity.

| Prop               | Type                                                              | Description                                                                      |
| ------------------ | ----------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| **`id`**           | <code>string</code>                                               | Logical identifier of the activity to update.                                    |
| **`contentState`** | <code><a href="#record">Record</a>&lt;string, string&gt;</code>   | Updated dynamic content state.                                                   |
| **`alert`**        | <code><a href="#alertconfiguration">AlertConfiguration</a></code> | Optional alert configuration to show a notification banner or Apple Watch alert. |
| **`timestamp`**    | <code>number</code>                                               | Optional UNIX timestamp for the update.                                          |


#### EndActivityOptions

Options for ending a Live Activity.

| Prop                  | Type                                                            | Description                                                                                                                                                                                                                                                                                                                                                                     |
| --------------------- | --------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`id`**              | <code>string</code>                                             | Logical identifier of the activity to end.                                                                                                                                                                                                                                                                                                                                      |
| **`contentState`**    | <code><a href="#record">Record</a>&lt;string, string&gt;</code> | Final dynamic content state to render before dismissal.                                                                                                                                                                                                                                                                                                                         |
| **`timestamp`**       | <code>number</code>                                             | Optional UNIX timestamp for the end event.                                                                                                                                                                                                                                                                                                                                      |
| **`dismissalDate`**   | <code>number</code>                                             | Optional future dismissal time (UNIX). If provided without `dismissalPolicy`, the `after` dismissal policy applies.                                                                                                                                                                                                                                                             |
| **`dismissalPolicy`** | <code>'default' \| 'immediate' \| 'after'</code>                | Optional dismissal policy. - `default`: the system default dismissal behavior. - `immediate`: dismiss the Live Activity immediately after ending it. - `after`: dismiss the Live Activity after `dismissalDate`; requires `dismissalDate`. If omitted, `dismissalDate` still maps to `after` for backward compatibility; otherwise the system default dismissal policy applies. |


#### LiveActivityState

Represents the state of a Live Activity returned by the plugin.

| Prop            | Type                                                            | Description                                            |
| --------------- | --------------------------------------------------------------- | ------------------------------------------------------ |
| **`id`**        | <code>string</code>                                             | System activity identifier (`Activity.id`).            |
| **`values`**    | <code><a href="#record">Record</a>&lt;string, string&gt;</code> | Current dynamic values.                                |
| **`isStale`**   | <code>boolean</code>                                            | Whether the activity is stale.                         |
| **`isEnded`**   | <code>boolean</code>                                            | Whether the activity has ended.                        |
| **`startedAt`** | <code>string</code>                                             | ISO string of when the activity started (if provided). |


#### ListActivitiesResult

Result of listing activities.

| Prop        | Type                                                              |
| ----------- | ----------------------------------------------------------------- |
| **`items`** | <code>{ id: string; activityId: string; state: string; }[]</code> |


#### UpdateTokenEndpointOptions

Options for native per-activity update token registration.

| Prop          | Type                                                            | Description                                                               |
| ------------- | --------------------------------------------------------------- | ------------------------------------------------------------------------- |
| **`url`**     | <code>string</code>                                             | Absolute HTTP(S) URL that receives the update token registration payload. |
| **`headers`** | <code><a href="#record">Record</a>&lt;string, string&gt;</code> | Optional HTTP headers added to the registration POST.                     |


#### PluginListenerHandle

| Prop         | Type                                      |
| ------------ | ----------------------------------------- |
| **`remove`** | <code>() =&gt; Promise&lt;void&gt;</code> |


#### PushTokenEvent

Event payload for per-activity live-activity push tokens.

| Prop             | Type                | Description                                                 |
| ---------------- | ------------------- | ----------------------------------------------------------- |
| **`id`**         | <code>string</code> | Your logical ID (the one you passed to start).              |
| **`activityId`** | <code>string</code> | System activity identifier (Activity.id).                   |
| **`token`**      | <code>string</code> | Hex-encoded APNs/FCM live activity token for this activity. |


#### PushToStartTokenEvent

Event payload for the global push-to-start token (iOS 17.2+).

| Prop        | Type                | Description                                           |
| ----------- | ------------------- | ----------------------------------------------------- |
| **`token`** | <code>string</code> | Hex-encoded APNs/FCM push-to-start token (iOS 17.2+). |


#### ActivityUpdateEvent

Event payload for activity lifecycle updates.

| Prop             | Type                | Description                               |
| ---------------- | ------------------- | ----------------------------------------- |
| **`id`**         | <code>string</code> | Your logical ID (attributes.id).          |
| **`activityId`** | <code>string</code> | System activity identifier (Activity.id). |
| **`state`**      | <code>string</code> | ActivityKit state as a string.            |


### Type Aliases


#### Record

Construct a type with a set of properties K of type T

<code>{ [P in K]: T; }</code>

</docgen-api>
