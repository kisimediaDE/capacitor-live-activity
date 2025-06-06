import { WebPlugin } from '@capacitor/core';

import type {
  LiveActivityPlugin,
  StartActivityOptions,
  UpdateActivityOptions,
  EndActivityOptions,
} from './definitions';

/**
 * Web implementation of the LiveActivityPlugin.
 * Live Activities are not supported on web and this class only provides mock methods.
 */
export class LiveActivityWeb extends WebPlugin implements LiveActivityPlugin {
  async startActivity(options: StartActivityOptions): Promise<void> {
    console.warn('[LiveActivity] startActivity is not supported on web.', options);
  }

  async updateActivity(options: UpdateActivityOptions): Promise<void> {
    console.warn('[LiveActivity] updateActivity is not supported on web.', options);
  }

  async endActivity(options: EndActivityOptions): Promise<void> {
    console.warn('[LiveActivity] endActivity is not supported on web.', options);
  }
}
