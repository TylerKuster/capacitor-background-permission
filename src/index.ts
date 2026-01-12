import { registerPlugin } from '@capacitor/core';

import type { BackgroundLocationPermissionPlugin } from './definitions';

/**
 * Check and request background location permissions
 * 
 * iOS: Automatically upgrades from WhenInUse to Always if possible
 * Android: Requests FINE_LOCATION then BACKGROUND_LOCATION sequentially
 * 
 * @returns Promise<LocationPermissionStatus>
 * 
 * @example
 * const status = await BackgroundLocationPermission.checkAndRequestPermission();
 * if (status.hasAlwaysPermission) {
 *   // Start geofencing
 * } else {
 *   // Show UI explaining why background location is needed
 * }
 */
const BackgroundLocationPermission = registerPlugin<BackgroundLocationPermissionPlugin>(
  'BackgroundLocationPermission',
  {
    web: () => import('./web').then(m => new m.BackgroundLocationPermissionWeb()),
  }
);

export * from './definitions';
export { BackgroundLocationPermission };

