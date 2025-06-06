# capacitor-live-activity

A Capacitor plugin for managing iOS Live Activities using ActivityKit and Swift.

## Install

```bash
npm install capacitor-live-activity
npx cap sync
```

## API

<docgen-index>

* [`startActivity(...)`](#startactivity)
* [`updateActivity(...)`](#updateactivity)
* [`endActivity(...)`](#endactivity)
* [Interfaces](#interfaces)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

Capacitor Plugin for managing iOS Live Activities.

### startActivity(...)

```typescript
startActivity(options: StartActivityOptions) => Promise<void>
```

Starts a new Live Activity on iOS using the provided options.

| Param         | Type                                                                  |
| ------------- | --------------------------------------------------------------------- |
| **`options`** | <code><a href="#startactivityoptions">StartActivityOptions</a></code> |

--------------------


### updateActivity(...)

```typescript
updateActivity(options: UpdateActivityOptions) => Promise<void>
```

Updates an existing Live Activity with new data.

| Param         | Type                                                                    |
| ------------- | ----------------------------------------------------------------------- |
| **`options`** | <code><a href="#updateactivityoptions">UpdateActivityOptions</a></code> |

--------------------


### endActivity(...)

```typescript
endActivity(options: EndActivityOptions) => Promise<void>
```

Ends a currently active Live Activity.

| Param         | Type                                                              |
| ------------- | ----------------------------------------------------------------- |
| **`options`** | <code><a href="#endactivityoptions">EndActivityOptions</a></code> |

--------------------


### Interfaces


#### StartActivityOptions

Options for starting a Live Activity.

| Prop               | Type                | Description                                                                     |
| ------------------ | ------------------- | ------------------------------------------------------------------------------- |
| **`id`**           | <code>string</code> | A unique identifier for the Live Activity instance.                             |
| **`title`**        | <code>string</code> | The main title shown in the Live Activity.                                      |
| **`subtitle`**     | <code>string</code> | Optional subtitle shown below the title.                                        |
| **`timerEndDate`** | <code>string</code> | The target date/time the timer or countdown ends. Must be an ISO 8601 string.   |
| **`imageBase64`**  | <code>string</code> | Optional image encoded as a Base64 string to be displayed in the Live Activity. |


#### UpdateActivityOptions

Options for updating an existing Live Activity.

| Prop               | Type                | Description                                               |
| ------------------ | ------------------- | --------------------------------------------------------- |
| **`id`**           | <code>string</code> | The identifier of the Live Activity to update.            |
| **`title`**        | <code>string</code> | Updated title.                                            |
| **`subtitle`**     | <code>string</code> | Updated subtitle.                                         |
| **`timerEndDate`** | <code>string</code> | New target date/time (ISO 8601) if the timer has changed. |
| **`imageBase64`**  | <code>string</code> | Updated image as Base64 string.                           |


#### EndActivityOptions

Options for ending a Live Activity.

| Prop            | Type                 | Description                                                                                                                 |
| --------------- | -------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| **`id`**        | <code>string</code>  | The identifier of the Live Activity to end.                                                                                 |
| **`dismissed`** | <code>boolean</code> | Whether the activity should be dismissed immediately or allowed to fade out naturally. Default: true (dismiss immediately). |

</docgen-api>
