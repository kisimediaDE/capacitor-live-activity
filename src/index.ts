import { registerPlugin } from '@capacitor/core';

import type { LiveActivityPlugin } from './definitions';

const LiveActivity = registerPlugin<LiveActivityPlugin>('LiveActivity', {
  web: () => import('./web').then((m) => new m.LiveActivityWeb()),
});

export * from './definitions';
export { LiveActivity };
