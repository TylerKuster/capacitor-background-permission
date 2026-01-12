package TylerKuster.capacitor.backgroundpermission;

import android.Manifest;
import android.app.Activity;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import java.util.HashMap;
import java.util.Map;

/**
 * Please read the Capacitor Android Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/android
 * 
 * Android Background Location Permission Implementation Notes:
 * 
 * Android Version-Specific Behavior:
 * 
 * Android 9 (API 28) and below:
 * - ACCESS_FINE_LOCATION permission is sufficient for both foreground and background location
 * - ACCESS_BACKGROUND_LOCATION permission does not exist on these versions
 * - Single permission request grants both foreground and background access
 * - Implementation should check Build.VERSION.SDK_INT before requesting BACKGROUND_LOCATION
 * 
 * Android 10 (API 29) and above:
 * - Requires both ACCESS_FINE_LOCATION and ACCESS_BACKGROUND_LOCATION permissions
 * - Must request permissions sequentially (cannot combine in single request)
 * - BACKGROUND_LOCATION can only be requested AFTER FINE_LOCATION is granted
 * - User sees two separate permission dialogs for better understanding
 * 
 * Why Permissions Can't Be Combined on Android 10+:
 * 
 * Google changed the permission model in Android 10 to give users more granular control
 * over background location access. Background location is considered a "special" permission
 * that requires explicit user consent separate from foreground location.
 * 
 * Attempting to request both permissions simultaneously would:
 * 1. Show a confusing dialog that doesn't clearly explain each permission level
 * 2. Violate Android's permission best practices
 * 3. Potentially be rejected during Play Store review
 * 
 * Sequential Request Pattern (Android 10+):
 * 1. First request: ACCESS_FINE_LOCATION (foreground location)
 * 2. Wait for user response via handleRequestPermissionsResult()
 * 3. If granted, immediately request: ACCESS_BACKGROUND_LOCATION (background location)
 * 4. Return final permission status to JavaScript
 * 
 * Implementation handles:
 * - Android version checking before requesting BACKGROUND_LOCATION
 * - Permission denial gracefully at each step
 * - Clear error messages if background permission is denied
 * - Activity lifecycle management (handles activity destruction during requests)
 */
@CapacitorPlugin(name = "BackgroundLocationPermission")
public class BackgroundLocationPermissionPlugin extends Plugin {

    private static final int REQUEST_CODE_FINE_LOCATION = 1001;
    private static final int REQUEST_CODE_BACKGROUND_LOCATION = 1002;
    /**
     * Minimum SDK version that requires separate BACKGROUND_LOCATION permission.
     * Android 10 (API 29) introduced ACCESS_BACKGROUND_LOCATION as a separate permission.
     * On Android 9 and below, ACCESS_FINE_LOCATION grants both foreground and background access.
     */
    private static final int MIN_SDK_FOR_BACKGROUND_LOCATION = 29; // Android 10 (API 29)

    private PluginCall pendingCall;
    private boolean isRequestingPermission = false;
    private boolean hasRequestedFineLocation = false;
    private boolean hasRequestedBackgroundLocation = false;
    private String currentRequestedPermission = null;

    @Override
    public void load() {
        super.load();
        // Restore state if activity was recreated
        Activity activity = getActivity();
        if (activity != null) {
            // Check if we have a saved state
            Bundle savedInstanceState = activity.getIntent().getExtras();
            if (savedInstanceState != null) {
                isRequestingPermission = savedInstanceState.getBoolean("isRequestingPermission", false);
                hasRequestedFineLocation = savedInstanceState.getBoolean("hasRequestedFineLocation", false);
                hasRequestedBackgroundLocation = savedInstanceState.getBoolean("hasRequestedBackgroundLocation", false);
            }
        }
    }

    /**
     * Requests background location permission on Android.
     * 
     * Android 9 and below:
     * - Requests ACCESS_FINE_LOCATION only (background access included)
     * - Returns hasAlwaysPermission: true if granted
     * 
     * Android 10+:
     * - First requests ACCESS_FINE_LOCATION (step 1)
     * - Then requests ACCESS_BACKGROUND_LOCATION (step 2)
     * - Returns hasAlwaysPermission: true only if both are granted
     * 
     * Note: Permissions must be requested sequentially, not simultaneously.
     * This is required by Android's permission system for background location.
     */
    @PluginMethod
    public void checkAndRequestPermission(PluginCall call) {
        // Check if already requesting permission
        // Prevents multiple simultaneous requests which could cause UI issues
        if (isRequestingPermission) {
            rejectWithError(call, "REQUEST_IN_PROGRESS", 
                "Permission request already in progress", 
                "A permission request is currently being processed. Please wait for it to complete before making another request.");
            return;
        }

        // Check SDK version compatibility
        // Note: This check currently rejects Android 9 and below, but the implementation
        // could be updated to support Android 9 by requesting only FINE_LOCATION
        if (Build.VERSION.SDK_INT < MIN_SDK_FOR_BACKGROUND_LOCATION) {
            rejectWithError(call, "SDK_VERSION_UNSUPPORTED", 
                "Background location requires Android 10 (API 29) or higher", 
                "Current SDK version: " + Build.VERSION.SDK_INT + ", required: " + MIN_SDK_FOR_BACKGROUND_LOCATION);
            return;
        }

        Activity activity = getActivity();
        if (activity == null) {
            rejectWithError(call, "ACTIVITY_DESTROYED", 
                "Activity is not available", 
                "The activity context is null. This may occur if the activity was destroyed or not properly initialized.");
            return;
        }

        // Check if activity is finishing or destroyed
        if (activity.isFinishing() || activity.isDestroyed()) {
            rejectWithError(call, "ACTIVITY_DESTROYED", 
                "Activity is finishing or destroyed", 
                "The activity is in the process of being destroyed or has already been destroyed.");
            return;
        }

        pendingCall = call;
        isRequestingPermission = true;
        hasRequestedFineLocation = false;
        hasRequestedBackgroundLocation = false;

        // Check current permission status
        checkAndRequestPermissionsSequentially();
    }

    /**
     * Checks current permission status and requests permissions sequentially.
     * 
     * Sequential Request Pattern (Android 10+):
     * 1. First check/request ACCESS_FINE_LOCATION (foreground location)
     * 2. Only after FINE_LOCATION is granted, check/request ACCESS_BACKGROUND_LOCATION
     * 
     * Why sequential and not simultaneous:
     * - Android 10+ requires BACKGROUND_LOCATION to be requested AFTER FINE_LOCATION
     * - Requesting both at once violates Android's permission model
     * - Sequential requests provide clearer user experience
     * - Each permission dialog can explain its specific purpose
     */
    private void checkAndRequestPermissionsSequentially() {
        Activity activity = getActivity();
        if (activity == null || activity.isFinishing() || activity.isDestroyed()) {
            if (pendingCall != null) {
                rejectWithError(pendingCall, "ACTIVITY_DESTROYED", 
                    "Activity became unavailable during permission request", 
                    "The activity was destroyed or finished while processing the permission request.");
                cleanup();
            }
            return;
        }

        // Step 1: Check FINE_LOCATION permission (foreground location)
        // This must be granted before we can request BACKGROUND_LOCATION
        int fineLocationStatus = ContextCompat.checkSelfPermission(activity, Manifest.permission.ACCESS_FINE_LOCATION);
        
        if (fineLocationStatus != PackageManager.PERMISSION_GRANTED) {
            // Request FINE_LOCATION first (required before BACKGROUND_LOCATION)
            hasRequestedFineLocation = true;
            currentRequestedPermission = Manifest.permission.ACCESS_FINE_LOCATION;
            
            // Check if we should show rationale
            if (ActivityCompat.shouldShowRequestPermissionRationale(activity, Manifest.permission.ACCESS_FINE_LOCATION)) {
                // User previously denied, show rationale (but we'll still request)
                bridge.getLog().info("Should show rationale for FINE_LOCATION permission");
            }
            
            // Request only FINE_LOCATION - cannot combine with BACKGROUND_LOCATION
            ActivityCompat.requestPermissions(activity, 
                new String[]{Manifest.permission.ACCESS_FINE_LOCATION}, 
                REQUEST_CODE_FINE_LOCATION);
            return;
        }

        // Step 2: FINE_LOCATION is granted, now check BACKGROUND_LOCATION
        // Only check/request BACKGROUND_LOCATION on Android 10+ (API 29+)
        if (Build.VERSION.SDK_INT >= MIN_SDK_FOR_BACKGROUND_LOCATION) {
            int backgroundLocationStatus = ContextCompat.checkSelfPermission(activity, 
                Manifest.permission.ACCESS_BACKGROUND_LOCATION);
            
            if (backgroundLocationStatus != PackageManager.PERMISSION_GRANTED) {
                // Request BACKGROUND_LOCATION (only after FINE_LOCATION is granted)
                hasRequestedBackgroundLocation = true;
                currentRequestedPermission = Manifest.permission.ACCESS_BACKGROUND_LOCATION;
                
                // Check if we should show rationale
                if (ActivityCompat.shouldShowRequestPermissionRationale(activity, 
                        Manifest.permission.ACCESS_BACKGROUND_LOCATION)) {
                    bridge.getLog().info("Should show rationale for BACKGROUND_LOCATION permission");
                }
                
                // Request only BACKGROUND_LOCATION - must be separate from FINE_LOCATION
                ActivityCompat.requestPermissions(activity, 
                    new String[]{Manifest.permission.ACCESS_BACKGROUND_LOCATION}, 
                    REQUEST_CODE_BACKGROUND_LOCATION);
                return;
            }
        }

        // Both permissions granted (or Android 9- where FINE_LOCATION is sufficient)
        resolveWithPermissions();
    }

    @Override
    public void handleRequestPermissionsResult(PluginCall call, int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.handleRequestPermissionsResult(call, requestCode, permissions, grantResults);
        
        if (pendingCall == null || !isRequestingPermission) {
            bridge.getLog().warn("Received permission result but no pending call or request in progress");
            return;
        }

        Activity activity = getActivity();
        if (activity == null || activity.isFinishing() || activity.isDestroyed()) {
            rejectWithError(pendingCall, "ACTIVITY_DESTROYED", 
                "Activity became unavailable during permission result handling", 
                "The activity was destroyed or finished while processing the permission result.");
            cleanup();
            return;
        }

        if (grantResults.length == 0) {
            rejectWithError(pendingCall, "PERMISSION_DENIED", 
                "Permission request returned empty results", 
                "The permission request did not return any results. This may indicate a system error.");
            cleanup();
            return;
        }

        boolean granted = grantResults[0] == PackageManager.PERMISSION_GRANTED;
        String permission = permissions[0];

        if (requestCode == REQUEST_CODE_FINE_LOCATION) {
            handleFineLocationResult(activity, permission, granted);
        } else if (requestCode == REQUEST_CODE_BACKGROUND_LOCATION) {
            handleBackgroundLocationResult(activity, permission, granted);
        } else {
            bridge.getLog().warn("Unknown request code: " + requestCode);
            cleanup();
        }
    }

    /**
     * Handles the result of FINE_LOCATION permission request.
     * 
     * If FINE_LOCATION is granted, immediately proceed to request BACKGROUND_LOCATION.
     * This demonstrates the sequential pattern - we cannot request both at once.
     */
    private void handleFineLocationResult(Activity activity, String permission, boolean granted) {
        if (!granted) {
            // Check if permanently denied
            boolean shouldShowRationale = ActivityCompat.shouldShowRequestPermissionRationale(activity, permission);
            if (!shouldShowRationale) {
                // User selected "Don't ask again"
                rejectWithError(pendingCall, "PERMANENTLY_DENIED", 
                    "Location permission was permanently denied", 
                    "The user denied the FINE_LOCATION permission and selected 'Don't ask again'. The user must enable it manually in app settings.");
            } else {
                rejectWithError(pendingCall, "PERMISSION_DENIED", 
                    "Location permission was denied", 
                    "The user denied the FINE_LOCATION permission. The permission can be requested again.");
            }
            cleanup();
            return;
        }

        // FINE_LOCATION granted, now request BACKGROUND_LOCATION
        // This is the sequential pattern - we must wait for FINE_LOCATION before requesting BACKGROUND_LOCATION
        bridge.getLog().info("FINE_LOCATION granted, requesting BACKGROUND_LOCATION");
        
        if (Build.VERSION.SDK_INT >= MIN_SDK_FOR_BACKGROUND_LOCATION) {
            int backgroundLocationStatus = ContextCompat.checkSelfPermission(activity, 
                Manifest.permission.ACCESS_BACKGROUND_LOCATION);
            
            if (backgroundLocationStatus != PackageManager.PERMISSION_GRANTED) {
                // Now that FINE_LOCATION is granted, we can request BACKGROUND_LOCATION
                // This must be a separate request - cannot combine with FINE_LOCATION
                hasRequestedBackgroundLocation = true;
                currentRequestedPermission = Manifest.permission.ACCESS_BACKGROUND_LOCATION;
                
                if (ActivityCompat.shouldShowRequestPermissionRationale(activity, 
                        Manifest.permission.ACCESS_BACKGROUND_LOCATION)) {
                    bridge.getLog().info("Should show rationale for BACKGROUND_LOCATION permission");
                }
                
                // Request BACKGROUND_LOCATION separately (step 2 of sequential pattern)
                ActivityCompat.requestPermissions(activity, 
                    new String[]{Manifest.permission.ACCESS_BACKGROUND_LOCATION}, 
                    REQUEST_CODE_BACKGROUND_LOCATION);
            } else {
                // Already has BACKGROUND_LOCATION
                resolveWithPermissions();
            }
        } else {
            // Android 9 and below: FINE_LOCATION is sufficient for background access
            // SDK doesn't support BACKGROUND_LOCATION, but we have FINE_LOCATION
            resolveWithPermissions();
        }
    }

    private void handleBackgroundLocationResult(Activity activity, String permission, boolean granted) {
        if (!granted) {
            // Check if permanently denied
            boolean shouldShowRationale = ActivityCompat.shouldShowRequestPermissionRationale(activity, permission);
            if (!shouldShowRationale) {
                // User selected "Don't ask again"
                rejectWithError(pendingCall, "PERMANENTLY_DENIED", 
                    "Background location permission was permanently denied", 
                    "The user denied the ACCESS_BACKGROUND_LOCATION permission and selected 'Don't ask again'. The user must enable it manually in app settings.");
            } else {
                // User denied but can request again - resolve with foreground only
                bridge.getLog().info("BACKGROUND_LOCATION denied, but FINE_LOCATION is granted");
                resolveWithPermissions();
            }
            cleanup();
            return;
        }

        // Both permissions granted
        resolveWithPermissions();
    }

    private void resolveWithPermissions() {
        if (pendingCall == null) {
            bridge.getLog().warn("Attempted to resolve but no pending call");
            cleanup();
            return;
        }

        Activity activity = getActivity();
        if (activity == null) {
            rejectWithError(pendingCall, "ACTIVITY_DESTROYED", 
                "Activity unavailable when resolving permissions", 
                "The activity context is null when attempting to resolve the permission request.");
            cleanup();
            return;
        }

        // Check current permission status
        int fineLocationStatus = ContextCompat.checkSelfPermission(activity, Manifest.permission.ACCESS_FINE_LOCATION);
        boolean hasForegroundLocation = fineLocationStatus == PackageManager.PERMISSION_GRANTED;
        
        boolean hasBackgroundLocation = false;
        if (Build.VERSION.SDK_INT >= MIN_SDK_FOR_BACKGROUND_LOCATION) {
            int backgroundLocationStatus = ContextCompat.checkSelfPermission(activity, 
                Manifest.permission.ACCESS_BACKGROUND_LOCATION);
            hasBackgroundLocation = backgroundLocationStatus == PackageManager.PERMISSION_GRANTED;
        }

        JSObject result = new JSObject();
        result.put("hasAlwaysPermission", hasBackgroundLocation);
        result.put("hasForegroundLocation", hasForegroundLocation);
        result.put("hasBackgroundLocation", hasBackgroundLocation);
        result.put("authorizationStatus", hasBackgroundLocation ? "always" : (hasForegroundLocation ? "whenInUse" : "denied"));

        bridge.getLog().info("Resolving permission request with result: " + result.toString());
        pendingCall.resolve(result);
        cleanup();
    }

    private void rejectWithError(PluginCall call, String code, String message, String details) {
        String errorMessage = code + ": " + message;
        if (details != null && !details.isEmpty()) {
            errorMessage += " | Details: " + details;
        }
        
        bridge.getLog().error("Rejecting permission request: " + errorMessage);
        call.reject(errorMessage, code, null);
    }

    private void cleanup() {
        isRequestingPermission = false;
        pendingCall = null;
        hasRequestedFineLocation = false;
        hasRequestedBackgroundLocation = false;
        currentRequestedPermission = null;
    }

    @Override
    public void handleOnDestroy() {
        super.handleOnDestroy();
        // If we have a pending call when the plugin is destroyed, reject it
        if (pendingCall != null && isRequestingPermission) {
            rejectWithError(pendingCall, "ACTIVITY_DESTROYED", 
                "Plugin destroyed during permission request", 
                "The plugin was destroyed (likely due to activity destruction) while a permission request was in progress.");
            cleanup();
        }
    }
}

