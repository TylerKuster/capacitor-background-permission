export interface BackgroundLocationPermissionPlugin {
  checkAndRequestPermission(): Promise<LocationPermissionStatus>;
}

export interface LocationPermissionStatus {
  hasAlwaysPermission: boolean;
  authorizationStatus: 'always' | 'whenInUse' | 'denied' | 'notDetermined' | 'restricted';
  hasBackgroundLocation?: boolean; // Android-specific
  hasForegroundLocation?: boolean; // Android-specific
}

