// web.ts
// Web shim: exposes the same API with no-ops for non-iOS platforms.

import { WebPlugin } from '@capacitor/core';
import type {
  LiveActivityPlugin,
  StartActivityOptions,
  UpdateActivityOptions,
  EndActivityOptions,
  LiveActivityState,
  ListActivitiesResult,
} from './definitions';

export class LiveActivityWeb extends WebPlugin implements LiveActivityPlugin {
  // ---- Local APIs ----
  async startActivity(_options: StartActivityOptions): Promise<void> {
    console.warn('LiveActivity: startActivity is only available on iOS.');
  }

  async updateActivity(_options: UpdateActivityOptions): Promise<void> {
    console.warn('LiveActivity: updateActivity is only available on iOS.');
  }

  async endActivity(_options: EndActivityOptions): Promise<void> {
    console.warn('LiveActivity: endActivity is only available on iOS.');
  }

  async isAvailable(): Promise<boolean> {
    console.warn('LiveActivity: isAvailable is only available on iOS.');
    return false;
  }

  async isRunning(_options: { id: string }): Promise<boolean> {
    console.warn('LiveActivity: isRunning is only available on iOS.');
    return false;
  }

  async getCurrentActivity(): Promise<LiveActivityState | undefined> {
    console.warn('LiveActivity: getCurrentActivity is only available on iOS.');
    return undefined;
  }

  // ---- Push-capable APIs ----
  async startActivityWithPush(_options: StartActivityOptions): Promise<{ activityId: string }> {
    console.warn('[LiveActivity] startActivityWithPush is only available on iOS.');
    return { activityId: '' };
  }

  async listActivities(): Promise<ListActivitiesResult> {
    console.warn('[LiveActivity] listActivities is only available on iOS.');
    return { items: [] };
  }

  async observePushToStartToken(): Promise<void> {
    console.warn('[LiveActivity] observePushToStartToken is only available on iOS.');
  }
}
