'use strict';

var core = require('@capacitor/core');

exports.BackgroundLocationPermissionErrorCode = void 0;
(function (BackgroundLocationPermissionErrorCode) {
    BackgroundLocationPermissionErrorCode["PERMISSION_DENIED"] = "PERMISSION_DENIED";
    BackgroundLocationPermissionErrorCode["PERMISSION_TIMEOUT"] = "PERMISSION_TIMEOUT";
    BackgroundLocationPermissionErrorCode["REQUEST_IN_PROGRESS"] = "REQUEST_IN_PROGRESS";
    BackgroundLocationPermissionErrorCode["PLATFORM_UNSUPPORTED"] = "PLATFORM_UNSUPPORTED";
    BackgroundLocationPermissionErrorCode["LOCATION_MANAGER_INIT_FAILED"] = "LOCATION_MANAGER_INIT_FAILED";
    BackgroundLocationPermissionErrorCode["APP_BACKGROUNDED"] = "APP_BACKGROUNDED";
    BackgroundLocationPermissionErrorCode["PERMANENTLY_DENIED"] = "PERMANENTLY_DENIED";
    BackgroundLocationPermissionErrorCode["SDK_VERSION_UNSUPPORTED"] = "SDK_VERSION_UNSUPPORTED";
    BackgroundLocationPermissionErrorCode["ACTIVITY_DESTROYED"] = "ACTIVITY_DESTROYED";
})(exports.BackgroundLocationPermissionErrorCode || (exports.BackgroundLocationPermissionErrorCode = {}));

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
const BackgroundLocationPermission = core.registerPlugin('BackgroundLocationPermission', {
    web: () => Promise.resolve().then(function () { return web; }).then(m => new m.BackgroundLocationPermissionWeb()),
});

class BackgroundLocationPermissionWeb extends core.WebPlugin {
    async checkAndRequestPermission() {
        const errorMessage = 'PLATFORM_UNSUPPORTED: Web platform is not supported | Details: Background location permissions are not available on web platforms. This feature requires native iOS or Android capabilities.';
        throw new Error(errorMessage);
    }
}

var web = /*#__PURE__*/Object.freeze({
    __proto__: null,
    BackgroundLocationPermissionWeb: BackgroundLocationPermissionWeb
});

exports.BackgroundLocationPermission = BackgroundLocationPermission;
//# sourceMappingURL=plugin.cjs.js.map
