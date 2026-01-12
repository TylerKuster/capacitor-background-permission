import { WebPlugin } from '@capacitor/core';

import type { BackgroundLocationPermissionPlugin, LocationPermissionStatus } from './definitions';

export class BackgroundLocationPermissionWeb
  extends WebPlugin
  implements BackgroundLocationPermissionPlugin
{
  async checkAndRequestPermission(): Promise<LocationPermissionStatus> {
    throw this.unimplemented('Web platform is not supported.');
  }
}

