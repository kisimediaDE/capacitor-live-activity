> [!CAUTION]
> ⚠️ This plugin is still under **active development**.  
> While basic functionality (start/update/end) is working, it is **not yet published on npm** and subject to change.  
> Use in production at your own risk.

# capacitor-live-activity

A Capacitor plugin for managing iOS Live Activities using ActivityKit and Swift.

## Install

```bash
npm install capacitor-live-activity
npx cap sync
```

> [!NOTE]
> This plugin requires **iOS 16.2+** to work properly due to `ActivityKit` API usage.

> [!IMPORTANT]
> This plugin **requires a Live Activity widget extension** to be present and configured in your Xcode project.  
> Without a widget, Live Activities will not appear on the lock screen or Dynamic Island.

## API

<docgen-index>

- [capacitor-live-activity](#capacitor-live-activity)
  - [Install](#install)
  - [API](#api)
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
