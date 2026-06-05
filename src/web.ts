// web.ts
// Web shim: exposes the same API with no-ops for non-iOS platforms.

import { WebPlugin } from '@capacitor/core';

import type {
  LiveActivityPlugin,
  StartActivityOptions,
  ScheduledActivityOptions,
  UpdateActivityOptions,
  EndActivityOptions,
  LiveActivityState,
  ListActivitiesResult,
  GetActivityPushTokensResult,
  UpdateTokenEndpointOptions,
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

  async isAvailable(): Promise<{ value: boolean }> {
    console.warn('LiveActivity: isAvailable is only available on iOS.');
    return { value: false };
  }

  async isRunning(_options: { id: string }): Promise<{ value: boolean }> {
    console.warn('LiveActivity: isRunning is only available on iOS.');
    return { value: false };
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

  async startActivityScheduled(_options: ScheduledActivityOptions): Promise<{ activityId: string }> {
    console.warn('[LiveActivity] startActivityScheduled is only available on iOS 26+.');
    return { activityId: '' };
  }

  async listActivities(): Promise<ListActivitiesResult> {
    console.warn('[LiveActivity] listActivities is only available on iOS.');
    return { items: [] };
  }

  async observePushToStartToken(): Promise<void> {
    console.warn('[LiveActivity] observePushToStartToken is only available on iOS.');
  }

  async setUpdateTokenEndpoint(_options: UpdateTokenEndpointOptions): Promise<void> {
    console.warn('[LiveActivity] setUpdateTokenEndpoint is only available on iOS.');
  }

  async getActivityPushTokens(): Promise<GetActivityPushTokensResult> {
    console.warn('[LiveActivity] getActivityPushTokens is only available on iOS.');
    return { items: [] };
  }
}
