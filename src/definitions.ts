export interface BackgroundLocationPermissionPlugin {
  checkAndRequestPermission(): Promise<LocationPermissionStatus>;
}

export interface LocationPermissionStatus {
  hasAlwaysPermission: boolean;
  authorizationStatus: 'always' | 'whenInUse' | 'denied' | 'notDetermined' | 'restricted';
  hasBackgroundLocation?: boolean; // Android-specific
  hasForegroundLocation?: boolean; // Android-specific
}

export enum BackgroundLocationPermissionErrorCode {
  PERMISSION_DENIED = 'PERMISSION_DENIED',
  PERMISSION_TIMEOUT = 'PERMISSION_TIMEOUT',
  REQUEST_IN_PROGRESS = 'REQUEST_IN_PROGRESS',
  PLATFORM_UNSUPPORTED = 'PLATFORM_UNSUPPORTED',
  LOCATION_MANAGER_INIT_FAILED = 'LOCATION_MANAGER_INIT_FAILED',
  APP_BACKGROUNDED = 'APP_BACKGROUNDED',
  PERMANENTLY_DENIED = 'PERMANENTLY_DENIED',
  SDK_VERSION_UNSUPPORTED = 'SDK_VERSION_UNSUPPORTED',
  ACTIVITY_DESTROYED = 'ACTIVITY_DESTROYED'
}

export interface BackgroundLocationPermissionError {
  code: BackgroundLocationPermissionErrorCode;
  message: string;
  details?: string;
}

