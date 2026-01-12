import Foundation
import Capacitor

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(BackgroundLocationPermissionPlugin)
public class BackgroundLocationPermissionPlugin: CAPPlugin {
    private let implementation = BackgroundLocationPermission()

    @objc func checkAndRequestPermission(_ call: CAPPluginCall) {
        // TODO: Implement iOS logic
        call.reject("Not implemented yet")
    }
}

