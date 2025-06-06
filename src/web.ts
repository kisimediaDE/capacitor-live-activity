import { WebPlugin } from '@capacitor/core';

import type { LiveActivityPlugin } from './definitions';

export class LiveActivityWeb extends WebPlugin implements LiveActivityPlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}
