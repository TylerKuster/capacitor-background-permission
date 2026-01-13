import { WebPlugin } from '@capacitor/core';
import type { BackgroundLocationPermissionPlugin, LocationPermissionStatus } from './definitions';
export declare class BackgroundLocationPermissionWeb extends WebPlugin implements BackgroundLocationPermissionPlugin {
    checkAndRequestPermission(): Promise<LocationPermissionStatus>;
}
//# sourceMappingURL=web.d.ts.map