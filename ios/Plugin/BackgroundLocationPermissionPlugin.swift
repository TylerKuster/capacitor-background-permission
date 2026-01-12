import Foundation
import Capacitor
import CoreLocation
import UIKit

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(BackgroundLocationPermissionPlugin)
public class BackgroundLocationPermissionPlugin: CAPPlugin, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager?
    private var pendingCall: CAPPluginCall?
    private var timeoutTimer: Timer?
    private let permissionQueue = DispatchQueue(label: "com.backgroundlocationpermission.queue", attributes: .concurrent)
    private var isRequestingPermission = false
    private var hasRequestedAlways = false
    private var backgroundObserver: NSObjectProtocol?
    private var foregroundObserver: NSObjectProtocol?
    private var wasBackgroundedDuringRequest = false
    
    public override func load() {
        super.load()
        
        // Initialize location manager with error handling
        locationManager = CLLocationManager()
        guard let manager = locationManager else {
            print("[BackgroundLocationPermission] ERROR: Failed to initialize CLLocationManager")
            return
        }
        manager.delegate = self
        
        // Set up app lifecycle observers
        setupAppLifecycleObservers()
    }
    
    private func setupAppLifecycleObservers() {
        let notificationCenter = NotificationCenter.default
        
        backgroundObserver = notificationCenter.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            if self.isRequestingPermission {
                print("[BackgroundLocationPermission] WARNING: App backgrounded during permission request")
                self.wasBackgroundedDuringRequest = true
            }
        }
        
        foregroundObserver = notificationCenter.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            // Check if we need to handle foreground return
            if self.isRequestingPermission && self.wasBackgroundedDuringRequest {
                // Check current status after returning to foreground
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.checkStatusAfterForegroundReturn()
                }
            }
        }
    }
    
    private func checkStatusAfterForegroundReturn() {
        guard let locationManager = locationManager else {
            rejectWithError(code: "LOCATION_MANAGER_INIT_FAILED", message: "Location manager not available after foreground return", details: "The location manager was not initialized or was deallocated")
            return
        }
        
        let currentStatus = locationManager.authorizationStatus
        
        // If status changed while backgrounded, resolve the call
        if currentStatus != .notDetermined {
            wasBackgroundedDuringRequest = false
            handleAuthorizationStatusChange(status: currentStatus)
        }
    }
    
    deinit {
        if let observer = backgroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = foregroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    /**
     * Main entry point for permission requests.
     * 
     * iOS Sequential Request Pattern:
     * iOS requires a two-step process for background location permissions:
     * 1. First request "When In Use" permission (if notDetermined)
     * 2. Then request "Always" permission upgrade (if WhenInUse granted)
     * 
     * This sequential pattern is required by iOS - you cannot request "Always" 
     * permission directly without first having "When In Use" permission.
     * 
     * The plugin handles this automatically by:
     * - Checking current authorization status
     * - Requesting WhenInUse if status is notDetermined
     * - Automatically requesting Always upgrade when WhenInUse is granted
     * - Using the CLLocationManagerDelegate to detect when each step completes
     */
    @objc func checkAndRequestPermission(_ call: CAPPluginCall) {
        permissionQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                self?.rejectWithError(code: "LOCATION_MANAGER_INIT_FAILED", message: "Plugin instance deallocated", details: "The plugin instance was deallocated before the permission request could complete")
                return
            }
            
            // Check if already requesting permission
            // Prevents multiple simultaneous requests which could cause UI issues
            if self.isRequestingPermission {
                DispatchQueue.main.async {
                    self.rejectCallWithError(call: call, code: "REQUEST_IN_PROGRESS", message: "Permission request already in progress", details: "A permission request is currently being processed. Please wait for it to complete before making another request.")
                }
                return
            }
            
            // Verify location manager is initialized
            guard let locationManager = self.locationManager else {
                DispatchQueue.main.async {
                    self.rejectCallWithError(call: call, code: "LOCATION_MANAGER_INIT_FAILED", message: "Location manager initialization failed", details: "CLLocationManager could not be initialized. This may indicate a system-level issue with location services.")
                }
                return
            }
            
            self.isRequestingPermission = true
            self.pendingCall = call
            self.wasBackgroundedDuringRequest = false
            
            DispatchQueue.main.async {
                self.handlePermissionRequest()
            }
        }
    }
    
    /**
     * Handles the permission request based on current authorization status.
     * 
     * iOS Sequential Request Pattern Implementation:
     * - notDetermined: Start with WhenInUse request (step 1 of 2)
     * - authorizedWhenInUse: Request Always upgrade (step 2 of 2)
     * - authorizedAlways: Already granted, return immediately
     * - denied/restricted: Return current status (user must enable in Settings)
     * 
     * The sequential pattern is critical because:
     * 1. iOS will crash if you request Always without first having WhenInUse
     * 2. Users see two separate dialogs, giving them clear understanding of each permission level
     * 3. Users can choose to keep "When In Use" only, which we must handle gracefully
     */
    private func handlePermissionRequest() {
        guard let locationManager = locationManager else {
            rejectWithError(code: "LOCATION_MANAGER_INIT_FAILED", message: "Location manager not initialized", details: "CLLocationManager instance is nil. This may occur if the plugin was not properly loaded or the location manager was deallocated.")
            return
        }
        
        let currentStatus = locationManager.authorizationStatus
        
        print("[BackgroundLocationPermission] Current authorization status: \(statusString(currentStatus))")
        
        switch currentStatus {
        case .notDetermined:
            // Step 1: Request "When In Use" permission first
            // This is required before requesting "Always" permission
            print("[BackgroundLocationPermission] Requesting WhenInUse permission first")
            hasRequestedAlways = false
            locationManager.requestWhenInUseAuthorization()
            startTimeoutTimer()
            
        case .authorizedWhenInUse:
            // Step 2: Upgrade to "Always" permission
            // User already has WhenInUse, now request Always upgrade
            print("[BackgroundLocationPermission] Upgrading to Always permission")
            hasRequestedAlways = true
            locationManager.requestAlwaysAuthorization()
            startTimeoutTimer()
            
        case .authorizedAlways:
            // Already has full permission, return immediately
            print("[BackgroundLocationPermission] Already has Always permission")
            resolvePermissionCall(status: .authorizedAlways)
            
        case .denied:
            // User denied permission, must enable in Settings
            print("[BackgroundLocationPermission] Permission denied")
            resolvePermissionCall(status: .denied)
            
        case .restricted:
            // Permission restricted by parental controls or MDM
            print("[BackgroundLocationPermission] Permission restricted")
            resolvePermissionCall(status: .restricted)
            
        @unknown default:
            // Handle future iOS versions that may add new statuses
            print("[BackgroundLocationPermission] Unknown authorization status")
            resolvePermissionCall(status: .denied)
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("[BackgroundLocationPermission] Authorization changed to: \(statusString(status))")
        
        // Check if app was backgrounded during request
        if wasBackgroundedDuringRequest {
            print("[BackgroundLocationPermission] App was backgrounded during request, checking status")
            wasBackgroundedDuringRequest = false
        }
        
        handleAuthorizationStatusChange(status: status)
    }
    
    /**
     * Handles authorization status changes from CLLocationManagerDelegate.
     * 
     * This is where the sequential request pattern is completed:
     * 
     * 1. When WhenInUse is granted (first request):
     *    - hasRequestedAlways flag is false
     *    - Automatically trigger Always request (step 2)
     *    - Don't resolve yet - wait for Always response
     * 
     * 2. When Always is granted (second request):
     *    - hasRequestedAlways flag is true
     *    - Resolve with success status
     * 
     * 3. When Always upgrade is denied:
     *    - hasRequestedAlways flag is true
     *    - Status is still authorizedWhenInUse
     *    - Resolve with WhenInUse status (partial success)
     * 
     * Note: iOS may call this delegate multiple times during the permission flow,
     * so we use the hasRequestedAlways flag to track which step we're on.
     */
    private func handleAuthorizationStatusChange(status: CLAuthorizationStatus) {
        guard let manager = locationManager else {
            rejectWithError(code: "LOCATION_MANAGER_INIT_FAILED", message: "Location manager unavailable during authorization change", details: "CLLocationManager instance became nil during the authorization status change callback")
            return
        }
        
        switch status {
        case .authorizedWhenInUse:
            if !hasRequestedAlways {
                // Step 1 complete: WhenInUse granted, now request Always (step 2)
                // This happens automatically after the first permission dialog
                print("[BackgroundLocationPermission] WhenInUse granted, requesting Always permission")
                hasRequestedAlways = true
                manager.requestAlwaysAuthorization()
                // Restart timeout for Always request
                startTimeoutTimer()
                // Don't resolve yet, wait for Always response
            } else {
                // User denied Always upgrade, resolve with WhenInUse status
                print("[BackgroundLocationPermission] Always upgrade was denied, resolving with WhenInUse")
                cancelTimeoutTimer()
                resolvePermissionCall(status: .authorizedWhenInUse)
            }
            
        case .authorizedAlways:
            print("[BackgroundLocationPermission] Always permission granted")
            cancelTimeoutTimer()
            resolvePermissionCall(status: .authorizedAlways)
            
        case .denied, .restricted:
            print("[BackgroundLocationPermission] Permission denied or restricted: \(statusString(status))")
            cancelTimeoutTimer()
            resolvePermissionCall(status: status)
            
        case .notDetermined:
            // Still waiting for response - this shouldn't happen after a request, but handle gracefully
            print("[BackgroundLocationPermission] Status is still notDetermined, continuing to wait")
            break
            
        @unknown default:
            print("[BackgroundLocationPermission] Unknown authorization status in delegate")
            cancelTimeoutTimer()
            resolvePermissionCall(status: .denied)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[BackgroundLocationPermission] Location manager error: \(error.localizedDescription)")
        // This is typically for location updates, not permission requests, but handle it anyway
        if isRequestingPermission {
            rejectWithError(code: "LOCATION_MANAGER_INIT_FAILED", message: "Location manager error occurred", details: "CLLocationManager reported an error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func resolvePermissionCall(status: CLAuthorizationStatus) {
        permissionQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            let hasAlwaysPermission = (status == .authorizedAlways)
            let authStatusString = self.statusString(status)
            
            DispatchQueue.main.async {
                guard let call = self.pendingCall else {
                    print("[BackgroundLocationPermission] Warning: No pending call to resolve")
                    return
                }
                
                let result: [String: Any] = [
                    "hasAlwaysPermission": hasAlwaysPermission,
                    "authorizationStatus": authStatusString
                ]
                
                print("[BackgroundLocationPermission] Resolving with result: \(result)")
                call.resolve(result)
                
                self.cleanup()
            }
        }
    }
    
    private func rejectWithError(code: String, message: String, details: String? = nil) {
        permissionQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                guard let call = self.pendingCall else {
                    print("[BackgroundLocationPermission] Warning: No pending call to reject")
                    return
                }
                
                var errorMessage = "\(code): \(message)"
                if let details = details {
                    errorMessage += " | Details: \(details)"
                }
                
                print("[BackgroundLocationPermission] Rejecting with error: \(errorMessage)")
                
                // Use reject with error code and message
                call.reject(errorMessage, code, nil)
                
                self.cleanup()
            }
        }
    }
    
    private func rejectCallWithError(call: CAPPluginCall, code: String, message: String, details: String? = nil) {
        var errorMessage = "\(code): \(message)"
        if let details = details {
            errorMessage += " | Details: \(details)"
        }
        
        print("[BackgroundLocationPermission] Rejecting call with error: \(errorMessage)")
        call.reject(errorMessage, code, nil)
    }
    
    private func statusString(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "notDetermined"
        case .restricted:
            return "restricted"
        case .denied:
            return "denied"
        case .authorizedWhenInUse:
            return "whenInUse"
        case .authorizedAlways:
            return "always"
        @unknown default:
            return "denied"
        }
    }
    
    private func startTimeoutTimer() {
        cancelTimeoutTimer()
        
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            print("[BackgroundLocationPermission] Permission request timed out after 30 seconds")
            
            // Check if app was backgrounded
            if self.wasBackgroundedDuringRequest {
                self.rejectWithError(
                    code: "APP_BACKGROUNDED",
                    message: "App was backgrounded during permission request",
                    details: "The app was moved to the background while waiting for the user to respond to the permission dialog. The permission request may still be pending."
                )
            } else {
                self.rejectWithError(
                    code: "PERMISSION_TIMEOUT",
                    message: "Permission request timed out",
                    details: "The user did not respond to the permission request within 30 seconds. This may indicate the permission dialog was dismissed or the user is not interacting with the app."
                )
            }
        }
    }
    
    private func cancelTimeoutTimer() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }
    
    private func cleanup() {
        cancelTimeoutTimer()
        pendingCall = nil
        isRequestingPermission = false
        hasRequestedAlways = false
        wasBackgroundedDuringRequest = false
    }
}

