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
declare const BackgroundLocationPermission: BackgroundLocationPermissionPlugin;
export * from './definitions';
export { BackgroundLocationPermission };
//# sourceMappingURL=index.d.ts.map