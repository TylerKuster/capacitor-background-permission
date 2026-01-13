import { WebPlugin } from '@capacitor/core';
export class BackgroundLocationPermissionWeb extends WebPlugin {
    async checkAndRequestPermission() {
        const errorMessage = 'PLATFORM_UNSUPPORTED: Web platform is not supported | Details: Background location permissions are not available on web platforms. This feature requires native iOS or Android capabilities.';
        throw new Error(errorMessage);
    }
}
