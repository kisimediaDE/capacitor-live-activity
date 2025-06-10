> [!CAUTION]
> ⚠️ This plugin is still under **active development**. ⚠️
>
> While basic functionality (start/update/end) is working, it is **not yet published on npm** and subject to change.  
> Use in production at your own risk.

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

<docgen-index>

- [⏱ capacitor-live-activity](#-capacitor-live-activity)
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
  - [📱 Example App](#-example-app)
  - [🛠 API](#-api)
    - [startActivity(...)](#startactivity)
    - [updateActivity(...)](#updateactivity)
    - [endActivity(...)](#endactivity)
    - [isAvailable()](#isavailable)
    - [isRunning(...)](#isrunning)
    - [getCurrentActivity(...)](#getcurrentactivity)
    - [Interfaces](#interfaces)
      - [StartActivityOptions](#startactivityoptions)
      - [UpdateActivityOptions](#updateactivityoptions)
      - [AlertConfiguration](#alertconfiguration)
      - [EndActivityOptions](#endactivityoptions)
      - [LiveActivityState](#liveactivitystate)
    - [Type Aliases](#type-aliases)
      - [Record](#record)

</docgen-index>

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

> By default, it’s located under: Pods > CapacitorLiveActivity > Shared > GenericAttributes.swift

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

### 5. Ensure Inclusion in Build

- In your **App target’s Info.plist**, ensure:

```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

- Clean and rebuild the project (Cmd + Shift + K, then Cmd + B).

## 📱 Example App

This plugin includes a fully functional demo app under the [`example-app/`](./example-app) directory.

The demo is designed to run on real iOS devices and showcases multiple Live Activity types like delivery, timer, taxi, workout, and more.

- Launch and test various Live Activities interactively
- Trigger updates and alert banners
- View JSON state changes in a live log console

> [!NOTE]
> For full instructions, see [example-app/README.md](./example-app/README.md)

## 🛠 API

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### startActivity(...)

```typescript
startActivity(options: StartActivityOptions) => Promise<void>
```

Starts a new Live Activity on iOS using the provided options.

| Param         | Type                                                                  |
| ------------- | --------------------------------------------------------------------- |
| **`options`** | <code><a href="#startactivityoptions">StartActivityOptions</a></code> |

**Since:** 0.0.1

---

### updateActivity(...)

```typescript
updateActivity(options: UpdateActivityOptions) => Promise<void>
```

Updates the currently active Live Activity.

| Param         | Type                                                                    |
| ------------- | ----------------------------------------------------------------------- |
| **`options`** | <code><a href="#updateactivityoptions">UpdateActivityOptions</a></code> |

**Since:** 0.0.1

---

### endActivity(...)

```typescript
endActivity(options: EndActivityOptions) => Promise<void>
```

Ends the Live Activity and optionally provides a final state and dismissal policy.

| Param         | Type                                                              |
| ------------- | ----------------------------------------------------------------- |
| **`options`** | <code><a href="#endactivityoptions">EndActivityOptions</a></code> |

**Since:** 0.0.1

---

### isAvailable()

```typescript
isAvailable() => Promise<boolean>
```

Returns whether Live Activities are available on this device and allowed by the user.

**Returns:** <code>Promise&lt;boolean&gt;</code>

**Since:** 0.0.1

---

### isRunning(...)

```typescript
isRunning(options: { id: string; }) => Promise<boolean>
```

Returns true if a Live Activity with the given ID is currently running.

| Param         | Type                         |
| ------------- | ---------------------------- |
| **`options`** | <code>{ id: string; }</code> |

**Returns:** <code>Promise&lt;boolean&gt;</code>

**Since:** 0.0.1

---

### getCurrentActivity(...)

```typescript
getCurrentActivity(options?: { id?: string | undefined; } | undefined) => Promise<LiveActivityState | undefined>
```

Returns the current active Live Activity state, if any.

If an ID is provided, returns that specific activity.
If no ID is given, returns the most recently started activity.

| Param         | Type                          |
| ------------- | ----------------------------- |
| **`options`** | <code>{ id?: string; }</code> |

**Returns:** <code>Promise&lt;<a href="#liveactivitystate">LiveActivityState</a>&gt;</code>

**Since:** 0.0.1

---

### Interfaces

#### StartActivityOptions

Options for starting a Live Activity.

| Prop               | Type                                                            | Description                                               |
| ------------------ | --------------------------------------------------------------- | --------------------------------------------------------- |
| **`id`**           | <code>string</code>                                             | Unique ID to identify the Live Activity.                  |
| **`attributes`**   | <code><a href="#record">Record</a>&lt;string, string&gt;</code> | Immutable attributes that are part of the Live Activity.  |
| **`contentState`** | <code><a href="#record">Record</a>&lt;string, string&gt;</code> | Initial content state (dynamic values).                   |
| **`timestamp`**    | <code>number</code>                                             | Optional timestamp (Unix) when the Live Activity started. |

#### UpdateActivityOptions

Options for updating a Live Activity.

| Prop               | Type                                                              | Description                                                                      |
| ------------------ | ----------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| **`id`**           | <code>string</code>                                               | ID of the Live Activity to update.                                               |
| **`contentState`** | <code><a href="#record">Record</a>&lt;string, string&gt;</code>   | Updated content state (dynamic values).                                          |
| **`alert`**        | <code><a href="#alertconfiguration">AlertConfiguration</a></code> | Optional alert configuration to show a notification banner or Apple Watch alert. |
| **`timestamp`**    | <code>number</code>                                               | Optional timestamp (Unix) when the update occurred.                              |

#### AlertConfiguration

Configuration for alert notifications.

| Prop        | Type                | Description                            |
| ----------- | ------------------- | -------------------------------------- |
| **`title`** | <code>string</code> | Optional title of the alert.           |
| **`body`**  | <code>string</code> | Optional body text of the alert.       |
| **`sound`** | <code>string</code> | Optional sound file name or "default". |

#### EndActivityOptions

Options for ending a Live Activity.

| Prop                | Type                                                            | Description                                                                            |
| ------------------- | --------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| **`id`**            | <code>string</code>                                             | ID of the Live Activity to end.                                                        |
| **`contentState`**  | <code><a href="#record">Record</a>&lt;string, string&gt;</code> | Final state to show before dismissal.                                                  |
| **`timestamp`**     | <code>number</code>                                             | Optional timestamp (Unix) when the end occurred.                                       |
| **`dismissalDate`** | <code>number</code>                                             | Optional dismissal time in the future (Unix). If not provided, system default applies. |

#### LiveActivityState

Represents an active Live Activity state.

| Prop            | Type                                                            | Description                                     |
| --------------- | --------------------------------------------------------------- | ----------------------------------------------- |
| **`id`**        | <code>string</code>                                             | The unique identifier of the activity.          |
| **`values`**    | <code><a href="#record">Record</a>&lt;string, string&gt;</code> | The current dynamic values of the activity.     |
| **`isStale`**   | <code>boolean</code>                                            | Whether the activity is stale.                  |
| **`isEnded`**   | <code>boolean</code>                                            | Whether the activity has ended.                 |
| **`startedAt`** | <code>string</code>                                             | ISO string timestamp when the activity started. |

### Type Aliases

#### Record

Construct a type with a set of properties K of type T

<code>{
 [P in K]: T;
 }</code>

</docgen-api>
