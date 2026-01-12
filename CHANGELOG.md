# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-XX

### Added
- Initial release of Capacitor Background Location Permission Plugin
- iOS implementation with sequential permission request pattern
  - Automatic "When In Use" to "Always" permission upgrade
  - Handles all iOS authorization states (notDetermined, denied, restricted, whenInUse, always)
  - App lifecycle management for permission requests
  - Timeout handling for permission dialogs
- Android implementation with version-specific behavior
  - Android 10+ (API 29+) sequential permission requests
  - Separate handling for ACCESS_FINE_LOCATION and ACCESS_BACKGROUND_LOCATION
  - Activity lifecycle management
  - Permission denial handling with permanent denial detection
- TypeScript definitions with comprehensive type safety
- Web platform stub implementation
- Comprehensive documentation in README.md
  - Installation instructions
  - iOS and Android configuration guides
  - Usage examples with different permission states
  - UI flow recommendations
  - Common pitfalls and solutions
  - Testing scenarios documentation
- Inline code comments explaining:
  - iOS sequential request pattern implementation
  - Android version-specific behavior differences
  - Why permissions can't be combined on Android 10+
- CHANGELOG.md for tracking version history

### Features
- `checkAndRequestPermission()` method that handles platform-specific permission flows
- Automatic sequential permission requests on both platforms
- Graceful handling of partial permissions (When In Use on iOS, foreground only on Android)
- Comprehensive error handling and timeout management
- Support for checking permission status without requesting

### Platform Support
- iOS 11.0+
- Android 10+ (API 29+) for background location
- Web (stub implementation)

### Known Limitations
- Android 9 and below: Currently requires Android 10+ for background location. Android 9 support could be added in future versions.
- Web platform: Returns stub values (not implemented)

### Documentation
- Complete README with examples and best practices
- Testing scenarios covering:
  - Fresh install (notDetermined state)
  - Upgrading from WhenInUse to Always
  - User denies permission
  - User denies then grants in settings
  - Android 9 vs Android 10+ behavior differences

[1.0.0]: https://github.com/TylerKuster/capacitor-background-permission/releases/tag/v1.0.0

