// definitions.ts
// Capacitor Plugin for iOS Live Activities (ActivityKit)
// Version: 7.1.0
// Platform: iOS 16.2+ (push-to-start requires iOS 17.2+)
// Author: Simon Kirchner
// License: MIT

import { PluginListenerHandle } from '@capacitor/core';

export interface LiveActivityPlugin {
  /**
   * Start a new Live Activity with local (on-device) ActivityKit.
   *
   * @since 0.0.1
   * @platform iOS
   */
  startActivity(options: StartActivityOptions): Promise<void>;

  /**
   * Start a new Live Activity locally **with push support** (`pushType: .token`).
   *
   * The per-activity APNs/FCM live-activity token will be emitted via
   * the `"liveActivityPushToken"` event shortly after starting.
   *
   * @returns An object containing the system `activityId`.
   * @since 7.1.0
   * @platform iOS
   */
  startActivityWithPush(options: StartActivityOptions): Promise<{ activityId: string }>;

  /**
   * Update an existing Live Activity (identified by your logical `id`).
   *
   * @since 0.0.1
   * @platform iOS
   */
  updateActivity(options: UpdateActivityOptions): Promise<void>;

  /**
   * End an existing Live Activity (identified by your logical `id`).
   *
   * Optionally provide a final state and a dismissal policy.
   *
   * @since 0.0.1
   * @platform iOS
   */
  endActivity(options: EndActivityOptions): Promise<void>;

  /**
   * Return whether Live Activities are enabled and allowed on this device.
   *
   * **Note:** This method resolves to `{ value: boolean }` to match native.
   *
   * @returns `{ value: boolean }`
   * @since 0.0.1
   * @platform iOS
   */
  isAvailable(): Promise<{ value: boolean }>; // NOTE: native currently returns { value: boolean }

  /**
   * Return whether a Live Activity with the given logical `id` is currently running.
   *
   * **Note:** This method resolves to `{ value: boolean }` to match native.
   *
   * @returns `{ value: boolean }`
   * @since 0.0.1
   * @platform iOS
   */
  isRunning(options: { id: string }): Promise<{ value: boolean }>; // NOTE: native currently returns { value: boolean }

  /**
   * Get the current Live Activity state.
   *
   * If an `id` is provided, returns that specific activity.
   * If no `id` is given, returns the most recently started activity.
   *
   * @returns The current state or `undefined` if none is active.
   * @since 0.0.1
   * @platform iOS
   */
  getCurrentActivity(options?: { id?: string }): Promise<LiveActivityState | undefined>;

  /**
   * List known activities (ActivityKit `active`/`stale`/`pending` etc.)
   * for the shared `GenericAttributes` type.
   *
   * Useful to discover activities that were started via push once the process
   * becomes aware of them.
   *
   * @returns A list of activity descriptors.
   * @since 7.1.0
   * @platform iOS
   */
  listActivities(): Promise<ListActivitiesResult>;

  /**
   * iOS 17.2+: begin streaming the global **push-to-start** token.
   *
   * The token will be emitted via `"liveActivityPushToStartToken"`.
   *
   * @since 7.1.0
   * @platform iOS 17.2+
   */
  observePushToStartToken(): Promise<void>;

  // ---------- Events ----------

  /**
   * Emitted when a per-activity live-activity push token becomes available
   * after calling `startActivityWithPush`.
   *
   * @since 7.1.0
   * @platform iOS
   */
  addListener(
    eventName: 'liveActivityPushToken',
    listenerFunc: (event: PushTokenEvent) => void,
  ): Promise<PluginListenerHandle>;

  /**
   * Emitted when a global **push-to-start** token is available (iOS 17.2+).
   *
   * @since 7.1.0
   * @platform iOS 17.2+
   */
  addListener(
    eventName: 'liveActivityPushToStartToken',
    listenerFunc: (event: PushToStartTokenEvent) => void,
  ): Promise<PluginListenerHandle>;

  /**
   * Emitted when the lifecycle of a Live Activity changes (e.g. active → stale).
   *
   * @since 7.1.0
   * @platform iOS
   */
  addListener(
    eventName: 'liveActivityUpdate',
    listenerFunc: (event: ActivityUpdateEvent) => void,
  ): Promise<PluginListenerHandle>;
}

// ---------- Data shapes ----------

/**
 * Options for starting a Live Activity.
 */
export interface StartActivityOptions {
  /**
   * Logical identifier you use to reference the activity.
   */
  id: string;

  /**
   * Immutable attributes for the activity.
   */
  attributes: Record<string, string>;

  /**
   * Initial dynamic content state.
   */
  contentState: Record<string, string>;

  /**
   * Optional UNIX timestamp when the activity started.
   */
  timestamp?: number;
}

/**
 * Options for updating a Live Activity.
 */
export interface UpdateActivityOptions {
  /**
   * Logical identifier of the activity to update.
   */
  id: string;

  /**
   * Updated dynamic content state.
   */
  contentState: Record<string, string>;

  /**
   * Optional alert configuration to show a notification banner or Apple Watch alert.
   */
  alert?: AlertConfiguration;

  /**
   * Optional UNIX timestamp for the update.
   */
  timestamp?: number;
}

/**
 * Options for ending a Live Activity.
 */
export interface EndActivityOptions {
  /**
   * Logical identifier of the activity to end.
   */
  id: string;

  /**
   * Final dynamic content state to render before dismissal.
   */
  contentState: Record<string, string>;

  /**
   * Optional UNIX timestamp for the end event.
   */
  timestamp?: number;

  /**
   * Optional future dismissal time (UNIX).
   * If omitted, the system default dismissal policy applies.
   */
  dismissalDate?: number;
}

/**
 * Represents the state of a Live Activity returned by the plugin.
 */
export interface LiveActivityState {
  /**
   * System activity identifier (`Activity.id`).
   */
  id: string;

  /**
   * Current dynamic values.
   */
  values: Record<string, string>;

  /**
   * Whether the activity is stale.
   */
  isStale: boolean;

  /**
   * Whether the activity has ended.
   */
  isEnded: boolean;

  /**
   * ISO string of when the activity started (if provided).
   */
  startedAt: string;
}

/**
 * Alert configuration shown for certain updates.
 */
export interface AlertConfiguration {
  /**
   * Optional title of the alert.
   */
  title?: string;

  /**
   * Optional body text of the alert.
   */
  body?: string;

  /**
   * Optional sound file name or "default".
   */
  sound?: string;
}

/**
 * Result of listing activities.
 * @since 7.1.0
 * @platform iOS
 */
export interface ListActivitiesResult {
  items: Array<{
    /** Your logical ID (attributes.id). */
    id: string;

    /** System activity identifier (Activity.id). */
    activityId: string;

    /** ActivityKit state as a string ("active" | "stale" | "pending" | "ended" | "dismissed"). */
    state: string;
  }>;
}

/**
 * Event payload for per-activity live-activity push tokens.
 * @since 7.1.0
 * @platform iOS
 */
export interface PushTokenEvent {
  /** Your logical ID (the one you passed to start). */
  id: string;

  /** System activity identifier (Activity.id). */
  activityId: string;

  /** Hex-encoded APNs/FCM live activity token for this activity. */
  token: string;
}

/**
 * Event payload for the global push-to-start token (iOS 17.2+).
 * @since 7.1.0
 * @platform iOS 17.2+
 */
export interface PushToStartTokenEvent {
  /** Hex-encoded APNs/FCM push-to-start token (iOS 17.2+). */
  token: string;
}

/**
 * Event payload for activity lifecycle updates.
 * @since 7.1.0
 * @platform iOS
 */
export interface ActivityUpdateEvent {
  /** Your logical ID (attributes.id). */
  id: string;

  /** System activity identifier (Activity.id). */
  activityId: string;

  /** ActivityKit state as a string. */
  state: string;
}
