// definitions.ts
// Capacitor Plugin for iOS Live Activities
// Version: 0.0.1
// Platform: iOS 16.1+
// Author: Simon Kirchner
// License: MIT

export interface LiveActivityPlugin {
  /**
   * Starts a new Live Activity on iOS using the provided options.
   *
   * @since 0.0.1
   * @platform iOS
   */
  startActivity(options: StartActivityOptions): Promise<void>;

  /**
   * Updates the currently active Live Activity.
   *
   * @since 0.0.1
   * @platform iOS
   */
  updateActivity(options: UpdateActivityOptions): Promise<void>;

  /**
   * Ends the Live Activity and optionally provides a final state and dismissal policy.
   *
   * @since 0.0.1
   * @platform iOS
   */
  endActivity(options: EndActivityOptions): Promise<void>;

  /**
   * Returns whether Live Activities are available on this device and allowed by the user.
   *
   * @since 0.0.1
   * @platform iOS
   */
  isAvailable(): Promise<boolean>;

  /**
   * Returns true if a Live Activity with the given ID is currently running.
   *
   * @since 0.0.1
   * @platform iOS
   */
  isRunning(options: { id: string }): Promise<boolean>;

  /**
   * Returns the current active Live Activity state, if any.
   *
   * If an ID is provided, returns that specific activity.
   * If no ID is given, returns the most recently started activity.
   *
   * @since 0.0.1
   * @platform iOS
   */
  getCurrentActivity(options?: { id?: string }): Promise<LiveActivityState | undefined>;
}

/**
 * Options for starting a Live Activity.
 */
export interface StartActivityOptions {
  /**
   * Unique ID to identify the Live Activity.
   */
  id: string;

  /**
   * Immutable attributes that are part of the Live Activity.
   */
  attributes: Record<string, string>;

  /**
   * Initial content state (dynamic values).
   */
  contentState: Record<string, string>;

  /**
   * Optional timestamp (Unix) when the Live Activity started.
   */
  timestamp?: number;
}

/**
 * Options for updating a Live Activity.
 */
export interface UpdateActivityOptions {
  /**
   * ID of the Live Activity to update.
   */
  id: string;

  /**
   * Updated content state (dynamic values).
   */
  contentState: Record<string, string>;

  /**
   * Optional alert configuration to show a notification banner or Apple Watch alert.
   */
  alert?: AlertConfiguration;

  /**
   * Optional timestamp (Unix) when the update occurred.
   */
  timestamp?: number;
}

/**
 * Options for ending a Live Activity.
 */
export interface EndActivityOptions {
  /**
   * ID of the Live Activity to end.
   */
  id: string;

  /**
   * Final state to show before dismissal.
   */
  contentState: Record<string, string>;

  /**
   * Optional timestamp (Unix) when the end occurred.
   */
  timestamp?: number;

  /**
   * Optional dismissal time in the future (Unix). If not provided, system default applies.
   */
  dismissalDate?: number;
}

/**
 * Represents an active Live Activity state.
 */
export interface LiveActivityState {
  /**
   * The unique identifier of the activity.
   */
  id: string;

  /**
   * The current dynamic values of the activity.
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
   * ISO string timestamp when the activity started.
   */
  startedAt: string;
}

/**
 * Configuration for alert notifications.
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
