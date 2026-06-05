// web.ts
// Web shim: exposes the same API with no-ops for non-iOS platforms.

import { WebPlugin } from '@capacitor/core';

import type {
  LiveActivityPlugin,
  LiveActivityState,
  ListActivitiesResult,
  GetActivityPushTokensResult,
} from './definitions';

export class LiveActivityWeb extends WebPlugin implements LiveActivityPlugin {
  // ---- Local APIs ----
  async startActivity(): Promise<void> {
    console.warn('LiveActivity: startActivity is only available on iOS.');
  }

  async updateActivity(): Promise<void> {
    console.warn('LiveActivity: updateActivity is only available on iOS.');
  }

  async endActivity(): Promise<void> {
    console.warn('LiveActivity: endActivity is only available on iOS.');
  }

  async isAvailable(): Promise<{ value: boolean }> {
    console.warn('LiveActivity: isAvailable is only available on iOS.');
    return { value: false };
  }

  async isRunning(): Promise<{ value: boolean }> {
    console.warn('LiveActivity: isRunning is only available on iOS.');
    return { value: false };
  }

  async getCurrentActivity(): Promise<LiveActivityState | undefined> {
    console.warn('LiveActivity: getCurrentActivity is only available on iOS.');
    return undefined;
  }

  // ---- Push-capable APIs ----
  async startActivityWithPush(): Promise<{ activityId: string }> {
    console.warn('[LiveActivity] startActivityWithPush is only available on iOS.');
    return { activityId: '' };
  }

  async startActivityScheduled(): Promise<{ activityId: string }> {
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

  async setUpdateTokenEndpoint(): Promise<void> {
    console.warn('[LiveActivity] setUpdateTokenEndpoint is only available on iOS.');
  }

  async getActivityPushTokens(): Promise<GetActivityPushTokensResult> {
    console.warn('[LiveActivity] getActivityPushTokens is only available on iOS.');
    return { items: [] };
  }
}
