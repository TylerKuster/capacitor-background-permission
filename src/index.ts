import { registerPlugin } from '@capacitor/core';

import type { BackgroundLocationPermissionPlugin } from './definitions';

const BackgroundLocationPermission = registerPlugin<BackgroundLocationPermissionPlugin>(
  'BackgroundLocationPermission',
  {
    web: () => import('./web').then(m => new m.BackgroundLocationPermissionWeb()),
  }
);

export * from './definitions';
export { BackgroundLocationPermission };

