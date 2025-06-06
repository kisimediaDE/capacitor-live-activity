/**
 * Options for starting a Live Activity.
 */
export interface StartActivityOptions {
  /**
   * A unique identifier for the Live Activity instance.
   */
  id: string;

  /**
   * The main title shown in the Live Activity.
   */
  title: string;

  /**
   * Optional subtitle shown below the title.
   */
  subtitle?: string;

  /**
   * The target date/time the timer or countdown ends.
   * Must be an ISO 8601 string.
   */
  timerEndDate: string;

  /**
   * Optional image encoded as a Base64 string to be displayed in the Live Activity.
   */
  imageBase64?: string;
}

/**
 * Options for updating an existing Live Activity.
 */
export interface UpdateActivityOptions {
  /**
   * The identifier of the Live Activity to update.
   */
  id: string;

  /**
   * Updated title.
   */
  title?: string;

  /**
   * Updated subtitle.
   */
  subtitle?: string;

  /**
   * New target date/time (ISO 8601) if the timer has changed.
   */
  timerEndDate?: string;

  /**
   * Updated image as Base64 string.
   */
  imageBase64?: string;
}

/**
 * Options for ending a Live Activity.
 */
export interface EndActivityOptions {
  /**
   * The identifier of the Live Activity to end.
   */
  id: string;

  /**
   * Whether the activity should be dismissed immediately or allowed to fade out naturally.
   * Default: true (dismiss immediately).
   */
  dismissed?: boolean;
}

/**
 * Capacitor Plugin for managing iOS Live Activities.
 */
export interface LiveActivityPlugin {
  /**
   * Starts a new Live Activity on iOS using the provided options.
   */
  startActivity(options: StartActivityOptions): Promise<void>;

  /**
   * Updates an existing Live Activity with new data.
   */
  updateActivity(options: UpdateActivityOptions): Promise<void>;

  /**
   * Ends a currently active Live Activity.
   */
  endActivity(options: EndActivityOptions): Promise<void>;
}
