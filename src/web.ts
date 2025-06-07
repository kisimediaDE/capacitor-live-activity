// web.ts
import { WebPlugin } from '@capacitor/core';
import type {
  LiveActivityPlugin,
  StartActivityOptions,
  UpdateActivityOptions,
  EndActivityOptions,
  LiveActivityState,
} from './definitions';

export class LiveActivityWeb extends WebPlugin implements LiveActivityPlugin {
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
}
