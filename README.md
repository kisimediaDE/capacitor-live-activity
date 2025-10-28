# 📡 capacitor-live-activity

[![npm](https://img.shields.io/npm/v/capacitor-live-activity)](https://www.npmjs.com/package/capacitor-live-activity)
[![bundle size](https://img.shields.io/bundlephobia/minzip/capacitor-live-activity)](https://bundlephobia.com/result?p=capacitor-live-activity)
[![License: MIT](https://img.shields.io/npm/l/capacitor-live-activity)](./LICENSE)
[![Platforms](https://img.shields.io/badge/platforms-iOS-orange)](#-platform-behavior)
[![Capacitor](https://img.shields.io/badge/capacitor-7.x-blue)](https://capacitorjs.com/)

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
  - [📱 Example App](#-example-app)
  - [🛠 API](#-api)
    - [startActivity(...)](#startactivity)
    - [startActivityWithPush(...)](#startactivitywithpush)
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
      - [UpdateActivityOptions](#updateactivityoptions)
      - [AlertConfiguration](#alertconfiguration)
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
- Real device required (no Simulator)
- For remote flows, test with the app in background/terminated

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
* [`updateActivity(...)`](#updateactivity)
* [`endActivity(...)`](#endactivity)
* [`isAvailable()`](#isavailable)
* [`isRunning(...)`](#isrunning)
* [`getCurrentActivity(...)`](#getcurrentactivity)
* [`listActivities()`](#listactivities)
* [`observePushToStartToken()`](#observepushtostarttoken)
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


#### UpdateActivityOptions

Options for updating a Live Activity.

| Prop               | Type                                                              | Description                                                                      |
| ------------------ | ----------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| **`id`**           | <code>string</code>                                               | Logical identifier of the activity to update.                                    |
| **`contentState`** | <code><a href="#record">Record</a>&lt;string, string&gt;</code>   | Updated dynamic content state.                                                   |
| **`alert`**        | <code><a href="#alertconfiguration">AlertConfiguration</a></code> | Optional alert configuration to show a notification banner or Apple Watch alert. |
| **`timestamp`**    | <code>number</code>                                               | Optional UNIX timestamp for the update.                                          |


#### AlertConfiguration

Alert configuration shown for certain updates.

| Prop        | Type                | Description                            |
| ----------- | ------------------- | -------------------------------------- |
| **`title`** | <code>string</code> | Optional title of the alert.           |
| **`body`**  | <code>string</code> | Optional body text of the alert.       |
| **`sound`** | <code>string</code> | Optional sound file name or "default". |


#### EndActivityOptions

Options for ending a Live Activity.

| Prop                | Type                                                            | Description                                                                                     |
| ------------------- | --------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| **`id`**            | <code>string</code>                                             | Logical identifier of the activity to end.                                                      |
| **`contentState`**  | <code><a href="#record">Record</a>&lt;string, string&gt;</code> | Final dynamic content state to render before dismissal.                                         |
| **`timestamp`**     | <code>number</code>                                             | Optional UNIX timestamp for the end event.                                                      |
| **`dismissalDate`** | <code>number</code>                                             | Optional future dismissal time (UNIX). If omitted, the system default dismissal policy applies. |


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

| Prop        | Type                                                                                                                                                                                                                                                                                          |
| ----------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`items`** | <code><a href="#array">Array</a>&lt;{ /** Your logical ID (attributes.id). */ id: string; /** System activity identifier (Activity.id). */ activityId: string; /** ActivityKit state as a string ("active" \| "stale" \| "pending" \| "ended" \| "dismissed"). */ state: string; }&gt;</code> |


#### Array

| Prop         | Type                | Description                                                                                            |
| ------------ | ------------------- | ------------------------------------------------------------------------------------------------------ |
| **`length`** | <code>number</code> | Gets or sets the length of the array. This is a number one higher than the highest index in the array. |

| Method             | Signature                                                                                                                     | Description                                                                                                                                                                                                                                 |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **toString**       | () =&gt; string                                                                                                               | Returns a string representation of an array.                                                                                                                                                                                                |
| **toLocaleString** | () =&gt; string                                                                                                               | Returns a string representation of an array. The elements are converted to string using their toLocalString methods.                                                                                                                        |
| **pop**            | () =&gt; T \| undefined                                                                                                       | Removes the last element from an array and returns it. If the array is empty, undefined is returned and the array is not modified.                                                                                                          |
| **push**           | (...items: T[]) =&gt; number                                                                                                  | Appends new elements to the end of an array, and returns the new length of the array.                                                                                                                                                       |
| **concat**         | (...items: <a href="#concatarray">ConcatArray</a>&lt;T&gt;[]) =&gt; T[]                                                       | Combines two or more arrays. This method returns a new array without modifying any existing arrays.                                                                                                                                         |
| **concat**         | (...items: (T \| <a href="#concatarray">ConcatArray</a>&lt;T&gt;)[]) =&gt; T[]                                                | Combines two or more arrays. This method returns a new array without modifying any existing arrays.                                                                                                                                         |
| **join**           | (separator?: string \| undefined) =&gt; string                                                                                | Adds all the elements of an array into a string, separated by the specified separator string.                                                                                                                                               |
| **reverse**        | () =&gt; T[]                                                                                                                  | Reverses the elements in an array in place. This method mutates the array and returns a reference to the same array.                                                                                                                        |
| **shift**          | () =&gt; T \| undefined                                                                                                       | Removes the first element from an array and returns it. If the array is empty, undefined is returned and the array is not modified.                                                                                                         |
| **slice**          | (start?: number \| undefined, end?: number \| undefined) =&gt; T[]                                                            | Returns a copy of a section of an array. For both start and end, a negative index can be used to indicate an offset from the end of the array. For example, -2 refers to the second to last element of the array.                           |
| **sort**           | (compareFn?: ((a: T, b: T) =&gt; number) \| undefined) =&gt; this                                                             | Sorts an array in place. This method mutates the array and returns a reference to the same array.                                                                                                                                           |
| **splice**         | (start: number, deleteCount?: number \| undefined) =&gt; T[]                                                                  | Removes elements from an array and, if necessary, inserts new elements in their place, returning the deleted elements.                                                                                                                      |
| **splice**         | (start: number, deleteCount: number, ...items: T[]) =&gt; T[]                                                                 | Removes elements from an array and, if necessary, inserts new elements in their place, returning the deleted elements.                                                                                                                      |
| **unshift**        | (...items: T[]) =&gt; number                                                                                                  | Inserts new elements at the start of an array, and returns the new length of the array.                                                                                                                                                     |
| **indexOf**        | (searchElement: T, fromIndex?: number \| undefined) =&gt; number                                                              | Returns the index of the first occurrence of a value in an array, or -1 if it is not present.                                                                                                                                               |
| **lastIndexOf**    | (searchElement: T, fromIndex?: number \| undefined) =&gt; number                                                              | Returns the index of the last occurrence of a specified value in an array, or -1 if it is not present.                                                                                                                                      |
| **every**          | &lt;S extends T&gt;(predicate: (value: T, index: number, array: T[]) =&gt; value is S, thisArg?: any) =&gt; this is S[]       | Determines whether all the members of an array satisfy the specified test.                                                                                                                                                                  |
| **every**          | (predicate: (value: T, index: number, array: T[]) =&gt; unknown, thisArg?: any) =&gt; boolean                                 | Determines whether all the members of an array satisfy the specified test.                                                                                                                                                                  |
| **some**           | (predicate: (value: T, index: number, array: T[]) =&gt; unknown, thisArg?: any) =&gt; boolean                                 | Determines whether the specified callback function returns true for any element of an array.                                                                                                                                                |
| **forEach**        | (callbackfn: (value: T, index: number, array: T[]) =&gt; void, thisArg?: any) =&gt; void                                      | Performs the specified action for each element in an array.                                                                                                                                                                                 |
| **map**            | &lt;U&gt;(callbackfn: (value: T, index: number, array: T[]) =&gt; U, thisArg?: any) =&gt; U[]                                 | Calls a defined callback function on each element of an array, and returns an array that contains the results.                                                                                                                              |
| **filter**         | &lt;S extends T&gt;(predicate: (value: T, index: number, array: T[]) =&gt; value is S, thisArg?: any) =&gt; S[]               | Returns the elements of an array that meet the condition specified in a callback function.                                                                                                                                                  |
| **filter**         | (predicate: (value: T, index: number, array: T[]) =&gt; unknown, thisArg?: any) =&gt; T[]                                     | Returns the elements of an array that meet the condition specified in a callback function.                                                                                                                                                  |
| **reduce**         | (callbackfn: (previousValue: T, currentValue: T, currentIndex: number, array: T[]) =&gt; T) =&gt; T                           | Calls the specified callback function for all the elements in an array. The return value of the callback function is the accumulated result, and is provided as an argument in the next call to the callback function.                      |
| **reduce**         | (callbackfn: (previousValue: T, currentValue: T, currentIndex: number, array: T[]) =&gt; T, initialValue: T) =&gt; T          |                                                                                                                                                                                                                                             |
| **reduce**         | &lt;U&gt;(callbackfn: (previousValue: U, currentValue: T, currentIndex: number, array: T[]) =&gt; U, initialValue: U) =&gt; U | Calls the specified callback function for all the elements in an array. The return value of the callback function is the accumulated result, and is provided as an argument in the next call to the callback function.                      |
| **reduceRight**    | (callbackfn: (previousValue: T, currentValue: T, currentIndex: number, array: T[]) =&gt; T) =&gt; T                           | Calls the specified callback function for all the elements in an array, in descending order. The return value of the callback function is the accumulated result, and is provided as an argument in the next call to the callback function. |
| **reduceRight**    | (callbackfn: (previousValue: T, currentValue: T, currentIndex: number, array: T[]) =&gt; T, initialValue: T) =&gt; T          |                                                                                                                                                                                                                                             |
| **reduceRight**    | &lt;U&gt;(callbackfn: (previousValue: U, currentValue: T, currentIndex: number, array: T[]) =&gt; U, initialValue: U) =&gt; U | Calls the specified callback function for all the elements in an array, in descending order. The return value of the callback function is the accumulated result, and is provided as an argument in the next call to the callback function. |


#### ConcatArray

| Prop         | Type                |
| ------------ | ------------------- |
| **`length`** | <code>number</code> |

| Method    | Signature                                                          |
| --------- | ------------------------------------------------------------------ |
| **join**  | (separator?: string \| undefined) =&gt; string                     |
| **slice** | (start?: number \| undefined, end?: number \| undefined) =&gt; T[] |


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
