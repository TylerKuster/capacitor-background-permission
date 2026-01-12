# Capacitor Background Location Permission Plugin

A Capacitor plugin for requesting and managing background location permissions on iOS and Android.

## Requirements

- **Capacitor**: 5.0.0 or 6.0.0+
- **iOS**: 13.0+
- **Android**: API 22+ (Android 5.1+)

## Installation

### 1. Install the Plugin

```bash
npm install capacitor-background-permission
```

### 2. Sync Native Projects

After installing the plugin, sync your Capacitor project to include the native code:

```bash
npx cap sync
```

This command will:

- Copy the plugin's native code to your iOS and Android projects
- Update native dependencies (CocoaPods for iOS, Gradle for Android)
- Ensure all plugin files are properly integrated

### 3. Platform-Specific Configuration

Follow the platform-specific setup instructions below.

## iOS Configuration

### Required Info.plist Entries

This plugin requires the following keys to be added to your app's `Info.plist` file:

- **NSLocationAlwaysAndWhenInUseUsageDescription** (required for iOS 11+)
- **NSLocationWhenInUseUsageDescription** (required)
- **NSLocationAlwaysUsageDescription** (required for iOS 10 compatibility)

These keys are **mandatory** for location permission requests. Without them, your app will crash when attempting to request location permissions.

### Automatic Configuration

#### Option 1: Using the Installation Script (Recommended)

Run the provided Ruby script to automatically add the required keys to your `Info.plist`:

```bash
# From your project root
ruby ios/Plugin/add_info_plist_keys.rb

# Or specify a custom path and description
ruby ios/Plugin/add_info_plist_keys.rb path/to/Info.plist "Your custom description"
```

The script will:

- Automatically find your `Info.plist` file
- Add all required keys with default descriptions
- Skip keys that already exist
- Provide clear feedback on what was added

**Default Description:**

> "This app requires background location access to provide geofencing features."

#### Option 2: Pod Install Warning

When you run `pod install`, the plugin's Podspec includes a `post_install` hook that automatically checks for the required Info.plist keys and warns you if any are missing. This helps catch configuration issues early.

### Manual Configuration

If you prefer to add the keys manually, edit your `ios/App/App/Info.plist` file and add:

```xml
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app requires background location access to provide geofencing features.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app requires background location access to provide geofencing features.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>This app requires background location access to provide geofencing features.</string>
```

**Important:** Customize the description strings to accurately reflect how your app uses location data. Apple may reject your app if the description doesn't match your actual usage.

### Customizing Descriptions

You should customize the permission descriptions to match your app's specific use case. For example:

- **Navigation apps:** "We need your location to provide turn-by-turn navigation and route guidance."
- **Fitness apps:** "We track your location to record your workout routes and provide distance metrics."
- **Delivery apps:** "We use your location to show nearby restaurants and track your delivery orders."

## Android Configuration

Android configuration is handled automatically through the plugin's Android manifest. The following permissions are automatically included when you run `npx cap sync`:

- `ACCESS_FINE_LOCATION` - Required for precise location access
- `ACCESS_COARSE_LOCATION` - Required for approximate location access
- `ACCESS_BACKGROUND_LOCATION` - Required for background location access (Android 10+)

**No additional setup is required** - these permissions are merged into your app's `AndroidManifest.xml` automatically during the sync process.

### Android Runtime Permissions

The plugin handles runtime permission requests automatically. On Android 10+ (API 29+), users will be presented with a system dialog to grant background location permission after granting foreground location permission.

## Plugin Registration

The plugin is automatically registered when you import it. No additional configuration is required in `capacitor.config.ts`.

### Automatic Registration

The plugin uses Capacitor's automatic plugin registration system. Simply import and use the plugin - no manual registration needed:

```typescript
import { BackgroundLocationPermission } from 'capacitor-background-permission';
```

### capacitor.config.ts

No special configuration is required in `capacitor.config.ts`. The plugin works out of the box:

```typescript
import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.example.app',
  appName: 'My App',
  webDir: 'dist',
  // No plugin-specific configuration needed
  // The plugin is automatically registered via Capacitor's plugin system
};

export default config;
```

### Initialization

The plugin does not require any initialization code. You can start using it immediately after installation and sync:

```typescript
// No initialization needed - just import and use
import { BackgroundLocationPermission } from 'capacitor-background-permission';

// Use directly in your components or services
const result = await BackgroundLocationPermission.checkAndRequestPermission();
```

### TypeScript Support

The plugin includes full TypeScript definitions. Make sure your project has TypeScript configured:

```json
{
  "compilerOptions": {
    "types": ["@capacitor/core"]
  }
}
```

Type definitions are automatically included when you install the plugin via npm.

## Usage

### Basic Implementation

```typescript
import { BackgroundLocationPermission } from 'capacitor-background-permission';

// Simple usage - request permission and check result
const result = await BackgroundLocationPermission.checkAndRequestPermission();

if (result.hasAlwaysPermission) {
  console.log('Background location access granted!');
  // Start your location services (geofencing, tracking, etc.)
} else {
  console.log('Permission status:', result.authorizationStatus);
  // Handle denied or partial permission
}
```

### Handling Different Permission States

Here's a comprehensive example showing how to handle all possible permission states:

```typescript
import { BackgroundLocationPermission } from 'capacitor-background-permission';
import { Capacitor } from '@capacitor/core';

async function requestLocationPermission() {
  try {
    const result = await BackgroundLocationPermission.checkAndRequestPermission();

    switch (result.authorizationStatus) {
      case 'always':
        // Full background location access granted
        console.log('✅ Always permission granted');
        enableBackgroundLocationFeatures();
        break;

      case 'whenInUse':
        // Only foreground location access
        console.log('⚠️ Only When In Use permission granted');
        showUpgradePrompt();
        enableForegroundLocationFeatures();
        break;

      case 'denied':
        // User denied permission
        console.log('❌ Permission denied');
        showSettingsRedirect();
        break;

      case 'restricted':
        // Permission restricted by parental controls or MDM
        console.log('🔒 Permission restricted');
        showRestrictedMessage();
        break;

      case 'notDetermined':
        // Should not happen after request, but handle gracefully
        console.log('⏳ Permission still not determined');
        break;
    }
  } catch (error) {
    console.error('Error requesting permission:', error);
    handlePermissionError(error);
  }
}

function showUpgradePrompt() {
  // Show UI explaining why Always permission is needed
  // Example: "To receive notifications when you arrive at locations,
  // please enable 'Always' location access in Settings."
}

function showSettingsRedirect() {
  // Guide user to Settings app to enable permission
  if (Capacitor.getPlatform() === 'ios') {
    // On iOS, you can use App.getLaunchUrl() or show instructions
    alert('Please enable location access in Settings > Privacy & Security > Location Services');
  } else {
    // On Android, you can open app settings
    // Note: This requires additional Capacitor plugin or native code
    alert('Please enable location access in Settings');
  }
}

function enableBackgroundLocationFeatures() {
  // Start geofencing, background tracking, etc.
}

function enableForegroundLocationFeatures() {
  // Start location services that work with When In Use permission
}
```

### UI Flow Recommendations

#### 1. Pre-Request Explanation

Always explain why you need location access before requesting it:

```typescript
async function requestPermissionWithExplanation() {
  // Show a modal or screen explaining:
  // - Why you need location access
  // - What features it enables
  // - How the data is used

  const userAccepted = await showPermissionExplanationModal();

  if (userAccepted) {
    const result = await BackgroundLocationPermission.checkAndRequestPermission();
    handlePermissionResult(result);
  }
}
```

#### 2. Progressive Permission Request

Request permission at the right moment in your user flow:

```typescript
// ❌ BAD: Requesting immediately on app launch
useEffect(() => {
  BackgroundLocationPermission.checkAndRequestPermission();
}, []);

// ✅ GOOD: Requesting when user tries to use location feature
async function startGeofencing() {
  const result = await BackgroundLocationPermission.checkAndRequestPermission();

  if (!result.hasAlwaysPermission) {
    // Show explanation and guide to settings
    return;
  }

  // Proceed with geofencing setup
}
```

#### 3. Handling Permission Denial

```typescript
async function handleLocationPermission() {
  const result = await BackgroundLocationPermission.checkAndRequestPermission();

  if (result.authorizationStatus === 'denied') {
    // Show a non-intrusive banner or button
    // "Location access is required for [feature].
    //  Tap here to enable it in Settings."

    // Store that permission was denied to avoid repeated prompts
    localStorage.setItem('locationPermissionDenied', 'true');
  }
}
```

#### 4. Re-checking After Settings Return

```typescript
import { App } from '@capacitor/app';

// Listen for app state changes
App.addListener('appStateChange', async ({ isActive }) => {
  if (isActive) {
    // User may have returned from Settings
    // Re-check permission status
    const result = await BackgroundLocationPermission.checkAndRequestPermission();

    if (result.hasAlwaysPermission) {
      // Permission was granted in Settings!
      enableBackgroundLocationFeatures();
    }
  }
});
```

### Common Pitfalls

#### ❌ Pitfall 1: Requesting Permission Too Early

**Problem:** Requesting permission immediately on app launch before the user understands why it's needed.

```typescript
// ❌ BAD
function App() {
  useEffect(() => {
    BackgroundLocationPermission.checkAndRequestPermission();
  }, []);
  // ...
}
```

**Solution:** Request permission contextually when the user tries to use a location feature.

```typescript
// ✅ GOOD
function GeofenceButton() {
  const handleClick = async () => {
    const result = await BackgroundLocationPermission.checkAndRequestPermission();
    if (result.hasAlwaysPermission) {
      startGeofencing();
    }
  };
  // ...
}
```

#### ❌ Pitfall 2: Not Handling "When In Use" State

**Problem:** Assuming `hasAlwaysPermission` is the only success state.

```typescript
// ❌ BAD
const result = await BackgroundLocationPermission.checkAndRequestPermission();
if (result.hasAlwaysPermission) {
  startBackgroundTracking(); // Crashes if only When In Use granted
}
```

**Solution:** Handle both `always` and `whenInUse` states appropriately.

```typescript
// ✅ GOOD
const result = await BackgroundLocationPermission.checkAndRequestPermission();
if (result.authorizationStatus === 'always') {
  startBackgroundTracking();
} else if (result.authorizationStatus === 'whenInUse') {
  startForegroundTracking();
  showUpgradeToAlwaysPrompt();
}
```

#### ❌ Pitfall 3: Not Checking Permission Before Each Use

**Problem:** Assuming permission persists across app sessions without verification.

```typescript
// ❌ BAD
// On app launch
const result = await BackgroundLocationPermission.checkAndRequestPermission();
if (result.hasAlwaysPermission) {
  // Start tracking and never check again
  startTracking();
}
```

**Solution:** Check permission status before critical location operations.

```typescript
// ✅ GOOD
async function startTracking() {
  const result = await BackgroundLocationPermission.checkAndRequestPermission();
  if (!result.hasAlwaysPermission) {
    throw new Error('Background location permission required');
  }
  // Proceed with tracking
}
```

#### ❌ Pitfall 4: Ignoring Error Cases

**Problem:** Not handling errors or edge cases.

```typescript
// ❌ BAD
const result = await BackgroundLocationPermission.checkAndRequestPermission();
// No error handling
```

**Solution:** Always wrap in try-catch and handle all states.

```typescript
// ✅ GOOD
try {
  const result = await BackgroundLocationPermission.checkAndRequestPermission();
  handlePermissionResult(result);
} catch (error) {
  console.error('Permission request failed:', error);
  // Show user-friendly error message
  showErrorToast('Unable to request location permission. Please try again.');
}
```

#### ❌ Pitfall 5: Requesting Multiple Times Simultaneously

**Problem:** Multiple components requesting permission at the same time.

```typescript
// ❌ BAD
// Component A
useEffect(() => {
  BackgroundLocationPermission.checkAndRequestPermission();
}, []);

// Component B (rendered at same time)
useEffect(() => {
  BackgroundLocationPermission.checkAndRequestPermission();
}, []);
```

**Solution:** Centralize permission requests or use a state management solution.

```typescript
// ✅ GOOD
// Create a permission service
class PermissionService {
  private requestPromise: Promise<LocationPermissionStatus> | null = null;

  async requestPermission(): Promise<LocationPermissionStatus> {
    if (this.requestPromise) {
      return this.requestPromise;
    }

    this.requestPromise = BackgroundLocationPermission.checkAndRequestPermission();
    const result = await this.requestPromise;
    this.requestPromise = null;
    return result;
  }
}
```

## API

### `checkAndRequestPermission()`

Requests background location permission if not already granted. On iOS, this will:

1. First request "When In Use" permission if not determined
2. Then automatically request "Always" permission upgrade
3. Return the final authorization status

**Returns:**

```typescript
{
  hasAlwaysPermission: boolean;
  authorizationStatus: 'notDetermined' | 'denied' | 'restricted' | 'whenInUse' | 'always';
}
```

## Testing Scenarios

When testing your app with this plugin, it's important to cover various permission states and user flows. Here are the key scenarios to test:

### 1. Fresh Install (notDetermined State)

**Scenario:** User installs the app for the first time and has never been prompted for location permission.

**Expected Behavior:**

- iOS: Two sequential dialogs appear:
  1. First: "Allow [App] to access your location?" with "While Using the App" and "Don't Allow" options
  2. Second (if user selects "While Using the App"): "Allow [App] to access your location even when you are not using the app?" with "Change to Always Allow" and "Keep Only While Using App" options
- Android: Two sequential dialogs appear:
  1. First: "Allow [App] to access this device's location?" (FINE_LOCATION)
  2. Second (if user grants first): "Allow [App] to access location in the background?" (BACKGROUND_LOCATION)

**Test Steps:**

1. Delete the app completely from the device
2. Reinstall the app
3. Trigger the permission request (e.g., tap a button that requires location)
4. Observe the permission dialogs
5. Grant both permissions
6. Verify `result.hasAlwaysPermission === true` and `result.authorizationStatus === 'always'`

### 2. Upgrading from WhenInUse to Always

**Scenario:** User previously granted "When In Use" permission and now needs to upgrade to "Always".

**Expected Behavior:**

- iOS: Only the second dialog appears (Always upgrade prompt)
- Android: Only the BACKGROUND_LOCATION dialog appears

**Test Steps:**

1. Set up device with app installed and only "When In Use" permission granted
   - iOS: Settings > Privacy & Security > Location Services > [Your App] > Select "While Using the App"
   - Android: Settings > Apps > [Your App] > Permissions > Location > Select "While using the app"
2. Open the app and trigger permission request
3. Observe that only the upgrade dialog appears
4. Grant "Always" permission
5. Verify `result.hasAlwaysPermission === true`

**Note:** On iOS, if the user previously selected "Keep Only While Using App" when prompted for Always, they must manually enable it in Settings. The plugin will detect this and return `whenInUse` status.

### 3. User Denies Permission

**Scenario:** User taps "Don't Allow" or "Deny" when prompted.

**Expected Behavior:**

- iOS: Returns `authorizationStatus: 'denied'` and `hasAlwaysPermission: false`
- Android: Returns `authorizationStatus: 'denied'` and `hasAlwaysPermission: false`
- Subsequent calls to `checkAndRequestPermission()` will not show dialogs (user must enable in Settings)

**Test Steps:**

1. Fresh install or reset permissions
2. Trigger permission request
3. Tap "Don't Allow" / "Deny" on the first dialog
4. Verify `result.authorizationStatus === 'denied'`
5. Trigger permission request again
6. Verify no dialog appears (permission is permanently denied until changed in Settings)

### 4. User Denies Then Grants in Settings

**Scenario:** User denies permission initially, then manually enables it in device Settings.

**Expected Behavior:**

- When app returns to foreground, re-checking permission should detect the new status
- Returns `authorizationStatus: 'always'` or `'whenInUse'` depending on what user selected in Settings

**Test Steps:**

1. Deny permission initially (see scenario 3)
2. Verify permission is denied in app
3. Open device Settings:
   - iOS: Settings > Privacy & Security > Location Services > [Your App] > Select "Always"
   - Android: Settings > Apps > [Your App] > Permissions > Location > Select "Allow all the time"
4. Return to the app
5. Re-check permission status (either automatically on app state change or manually)
6. Verify `result.hasAlwaysPermission === true` (if Always was selected)

**Implementation Tip:** Use `App.addListener('appStateChange')` to detect when user returns from Settings.

### 5. Android 9 vs Android 10+ Behavior Differences

**Scenario:** Testing on different Android versions to understand platform differences.

**Expected Behavior:**

**Android 9 (API 28) and below:**

- `ACCESS_FINE_LOCATION` permission is sufficient for background location
- `ACCESS_BACKGROUND_LOCATION` permission does not exist
- Single permission request grants both foreground and background access
- Plugin should handle this gracefully (check Android version before requesting BACKGROUND_LOCATION)

**Android 10 (API 29) and above:**

- Requires both `ACCESS_FINE_LOCATION` and `ACCESS_BACKGROUND_LOCATION`
- Must request permissions sequentially (cannot combine in single request)
- User sees two separate permission dialogs
- Background location permission can only be requested after foreground location is granted

**Test Steps:**

**On Android 9:**

1. Install app on Android 9 device/emulator
2. Trigger permission request
3. Verify only one dialog appears (FINE_LOCATION)
4. Grant permission
5. Verify `result.hasAlwaysPermission === true` (background access granted automatically)

**On Android 10+:**

1. Install app on Android 10+ device/emulator
2. Trigger permission request
3. Verify first dialog appears (FINE_LOCATION)
4. Grant first permission
5. Verify second dialog appears immediately (BACKGROUND_LOCATION)
6. Grant second permission
7. Verify `result.hasAlwaysPermission === true`

**Why Permissions Can't Be Combined on Android 10+:**

- Google changed the permission model to give users more granular control
- Background location is considered a "special" permission that requires explicit user consent
- Requesting both simultaneously would show a confusing dialog
- Sequential requests provide clearer user experience and better explanation of what each permission enables

### Additional Testing Scenarios

#### Restricted Permission (iOS)

- Test on device with parental controls or MDM restrictions
- Verify `authorizationStatus === 'restricted'`
- App should handle gracefully without crashing

#### Permission Timeout

- Test scenario where user doesn't respond to permission dialog
- Plugin has 15-second timeout
- Verify error handling when timeout occurs

#### App Backgrounded During Request

- Request permission, then immediately background the app
- Return to foreground
- Verify plugin correctly detects final permission state

#### Multiple Rapid Requests

- Test calling `checkAndRequestPermission()` multiple times quickly
- Verify plugin prevents concurrent requests
- Verify only one permission dialog appears

## Troubleshooting

### iOS: App crashes when requesting permission

**Solution:** Make sure all three required Info.plist keys are present:

- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysUsageDescription`

Run the installation script or check manually:

```bash
ruby ios/Plugin/add_info_plist_keys.rb
```

### iOS: Permission dialog doesn't appear

**Possible causes:**

1. Info.plist keys are missing (see above)
2. Permission was previously denied (user must enable in Settings)
3. App is running in simulator (some permission behaviors differ)

### iOS: Only "When In Use" permission granted

This is expected behavior. The plugin will attempt to upgrade to "Always" permission, but users can choose to keep "When In Use" only. Check the `authorizationStatus` in the result to see what was granted.

## License

MIT
