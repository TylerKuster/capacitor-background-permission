import { WebPlugin } from '@capacitor/core';

import type { BackgroundLocationPermissionPlugin, LocationPermissionStatus } from './definitions';

export class BackgroundLocationPermissionWeb
  extends WebPlugin
  implements BackgroundLocationPermissionPlugin
{
  async checkAndRequestPermission(): Promise<LocationPermissionStatus> {
    const errorMessage = 'PLATFORM_UNSUPPORTED: Web platform is not supported | Details: Background location permissions are not available on web platforms. This feature requires native iOS or Android capabilities.';
    throw new Error(errorMessage);
  }
}

