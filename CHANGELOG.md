# iProov Face Flutter SDK

## 7.0.0

iProov Face Flutter SDK v7.0.0 includes the following changes

### Flutter

* Added `IProov.isSessionActive()`, which returns whether a session is currently active. Use it to detect and clean up a stale session before calling `launch()` again, avoiding `CaptureAlreadyActiveException`.
* Fixed `IProov.cancel()` hanging forever on Android: the native handler now always replies, so the returned `Future` completes.
* **Breaking:** `IProov.cancel()` now returns `Future<void>` instead of `Future<bool>`. It is safe to call unconditionally, and `isSessionActive()` is the way to check whether a session has finished.
* **Breaking:** `Canceler.app` has been renamed to `Canceler.integration`, matching the native SDKs.


### Android

* Upgraded SDK to [v12.0.0](https://github.com/iProov/android/releases/tag/v12.0.0).
* `CaptureAlreadyActiveException` is now routed to Dart as an `IProovEventError` instead of being swallowed inside a coroutine.
* Session cancellation from `subscription.cancel()` is now performed synchronously rather than in a fire-and-forget coroutine.

### iOS

* Upgraded SDK to [v14.0.0](https://github.com/iProov/ios/releases/tag/14.0.0).
* Added Swift Package Manager support. The plugin works with both Swift Package Manager and CocoaPods, and Flutter picks one when it builds your app: Flutter 3.44 and above uses Swift Package Manager by default, and earlier versions use CocoaPods. No changes are needed in your app.
* Added an "Avoiding `CaptureAlreadyActiveException`" section describing both the normal terminal-event flow and stale-session recovery via `isSessionActive()` / `cancel()`.

### Breaking changes

* Removed `Options.orientation` and the `Orientation` enum.
* `IProovEventSuccess` no longer carries a `frame`. 
* `IProovEventFailure` no longer carries a `frame`.
* Removed `ListenerNotRegisteredException`. The corresponding error no longer exists in either
  native SDK, so it could never be thrown.
* Raised the Android requirements to compileSdk 36, Kotlin 2.0.21, Android Gradle Plugin 8.9.1 and
  JDK 17.
* Raised the iOS requirements to iOS 16 and Xcode 26.

### Behavioural changes

* The default `filter` is now `NaturalFilter` (previously `LineDrawingFilter`). If you rely on the
  previous appearance, set `filter` explicitly.

### Added

* Added `IProov.nativeSdkVersion()`, which returns the version of the native iProov SDK.
* New `accessibility` options under `genuinePresenceAssurance` (`isVibrationEnabled`,
  `isSoundEnabled`, `isColorEnabled`).
* New exceptions `UnsupportedOSVersionException` and `UnsupportedSDKVersionException`.
* Support for the new iOS `unsupportedDevice` error, mapped to `UnsupportedDeviceException`
  alongside the legacy `notSupported` spelling of the same error.
* New exceptions `ConsentRequiredException` and `SessionCannotBeStartedTwiceException` (Android
  only). These native errors already existed but were previously surfaced as
  `UnexpectedErrorException`.

### Fixed

* Errors from the key pair API (`keyPair.sign()`, `publicKey.getPem()`, `publicKey.getDer()`) now
  throw the matching `IProovException`. Previously the native exception escaped the Android plugin
  and was reported to Dart as a `MissingPluginException`. Android only.


## 6.1.0

iProov Face Flutter SDK v6.1.0 includes the following changes

### iOS

* Upgraded SDK to [v13.1.0](https://github.com/iProov/ios/releases/tag/13.1.0).

### Android

* Upgraded SDK to [v11.1.0](https://github.com/iProov/android/releases/tag/v11.1.0).

## 6.0.0

iProov Face Flutter SDK v6.0.0 includes the following changes

### Flutter

- Adding the new Options in genuinePresenceAssurance(controlYPosition, controlXPosition, and scanningPrompts)
- Increase min Flutter version to 3.27.0
- Increase min Dart version to 3.0.0

### iOS

* Upgraded SDK to [v13.0.0](https://github.com/iProov/ios/releases/tag/13.0.0).

### Android

- Upgrading Android target sdk to 36
- Kotlin 1.8.10
* Upgraded SDK to [v11.0.0](https://github.com/iProov/android/releases/tag/v11.0.0).


## 5.3.0

iProov Face Flutter SDK v5.3.0 includes the following changes

### iOS

* Upgraded SDK to [v12.5.0](https://github.com/iProov/ios/releases/tag/12.5.0).

### Android

* Upgraded SDK to [v10.4.0](https://github.com/iProov/android/releases/tag/v10.4.0).


## 5.2.0

iProov Face Flutter SDK v5.2.0 includes the following changes

### iOS

* Upgraded SDK to [v12.4.1](https://github.com/iProov/ios/releases/tag/12.4.1).

### Android

* Upgraded SDK to [v10.3.2](https://github.com/iProov/android/releases/tag/v10.3.2).


## 5.1.0

iProov Face Flutter SDK v5.1.0 includes the following changes

### iOS

* Upgraded SDK to [v12.3.0](https://github.com/iProov/ios/releases/tag/12.3.0).

### Android

* Upgraded SDK to [v10.3.0](https://github.com/iProov/android/releases/tag/v10.3.0).


## 5.0.2

iProov Face Flutter SDK v5.0.2 includes the following changes

### Flutter

- Upgrading Android Example App to Gradle 8 for improved performance and maintainability.

### Android
  
* Added namespace field to Gradle build configuration.


## 5.0.1

iProov Face Flutter SDK v5.0.1 includes the following changes

### Flutter

- An `else` branch has been added to the `when` expression to ensure it handles all possible cases, preventing potential crashes.


## 5.0.0

iProov Face Flutter SDK v5.0.0 includes the following changes

### iOS

* Upgraded SDK to [v12.0.0](https://github.com/iProov/ios/releases/tag/12.0.0).
* Requires iOS 13 and above

### Android

* Upgraded SDK to [v10.0.0](https://github.com/iProov/android/releases/tag/v10.0.0).
* Requires Android API Level 26 (Android 8 Oreo) and above


## 4.0.4

* Added `additionalOptions` parameter to `getToken()` in the Dart API client.


## 4.0.3

iProov Face Flutter SDK v4.0.3 includes the following changes

### Flutter

- New UI Event API.

### iOS

* Upgraded SDK to [v11.1.1](https://github.com/iProov/ios/releases/tag/11.1.1).

### Android

* Upgraded SDK to [v9.1.1](https://github.com/iProov/android/releases/tag/v9.1.1).


## 4.0.2

iProov Face Flutter SDK v4.0.2 includes the following changes

### iOS

* Upgraded SDK to [v11.0.3](https://github.com/iProov/ios/releases/tag/11.0.3).

### Android

* Upgraded SDK to [v9.0.3](https://github.com/iProov/android/releases/tag/v9.0.3).


## 4.0.1

iProov Face Flutter SDK v4.0.1 includes the following changes

### Flutter

- The `certificates` option is now `List<String>?`. The base64-encoded SHA-256 hash of a certificate's Subject Public Key Info is used to add a certificate.
- Removed unnecessary `meta` library


## 4.0.0

iProov SDK Face Flutter SDK v4.0.0 is a major update which includes a number of improvements and breaking changes.

Please consult the [Upgrade Guide](https://github.com/iProov/flutter/wiki/Upgrade-Guide#upgrading-to-v40) for detailed instructions on how to upgrade to this new version.


### Flutter

* To support the changes in SDK version iOS v11 and Android v9, the following have been updated:
	* The following `Options` have been removed:
		* `faceDetector`, `maxPitch`, `maxYaw` and `maxRaw`
	* `UserTimeout` exception has been added to `IProovException`
	* `IProov.Canceller` becomes `IProov.Canceler`

### iOS

* Upgraded SDK to [v11.0.0](https://github.com/iProov/ios/releases/tag/11.0.0).
* Requires iOS 12.0 and above

### Android

* Upgraded SDK to [v9.0.1](https://github.com/iProov/android/releases/tag/v9.0.1).
* Updated Gradle to version 7.5 and Gradle build tools to 7.4.1


### Example app

* Updated the Gradle to version 7.5 and Gradle build tools to 7.4.1

## 3.2.0

iProov Face Flutter SDK v3.2.0 includes the following changes

### Flutter

- Declared support for Dart 3.
- Dependency on [image](https://pub.dev/packages/image) package upgraded to 4.0.0
- Added `copyWith()` implementation to `Options`.
- `Options` classes are now marked `@immutable`.

### iOS

* Upgraded SDK to [v10.3.0](https://github.com/iProov/ios/releases/tag/10.3.0).

### Android

* Upgraded SDK to [v8.5.0](https://github.com/iProov/android/releases/tag/v8.5.0).

### API Client

- All methods now have named parameters.
- `enrolPhotoAndGetVerifyToken()` now supports passing assurance type.

## 3.1.1

iProov Face Flutter SDK v3.1.1 includes an additional certificate added to the default certificate pinning, to support beyond Dec 2023.

### iOS

* Upgraded SDK to [v10.1.3](https://github.com/iProov/ios/releases/tag/10.1.3).

### Android

* Upgraded SDK to [v8.3.1](https://github.com/iProov/android/releases/tag/v8.3.1).

## 3.1.0

iProov SDK Face Flutter SDK v3.1.0 includes bug fixes 

Please consult the [Upgrade Guide](https://github.com/iProov/flutter/wiki/Upgrade-Guide#upgrading-to-v30) for detailed instructions on how to upgrade to this new version.

### Flutter

* Fix how `feedbackCode`, `reason` and `frame` values are returned by `IProovEventFailure`, and value `frame` by `IProovEventSucces` in the Android side.

### iOS

* Upgraded SDK to [v10.1.2](https://github.com/iProov/ios/releases/tag/10.1.2).

### Android

* Upgraded SDK to [v8.3.0](https://github.com/iProov/android/releases/tag/v8.3.0).


## 3.1.0

iProov SDK Face Flutter SDK v3.1.0 includes bug fixes 

Please consult the [Upgrade Guide](https://github.com/iProov/flutter/wiki/Upgrade-Guide#upgrading-to-v30) for detailed instructions on how to upgrade to this new version.

### Flutter

* Fix how `feedbackCode`, `reason` and `frame` values are returned by `IProovEventFailure`, and value `frame` by `IProovEventSucces` in the Android side.

### iOS

* Upgraded SDK to [v10.1.2](https://github.com/iProov/ios/releases/tag/10.1.2).

### Android

* Upgraded SDK to [v8.3.0](https://github.com/iProov/android/releases/tag/v8.3.0).


## 3.0.0

iProov SDK Face Flutter SDK v3.0.0 is a major update which includes a number of improvements and breaking changes.

Please consult the [Upgrade Guide](https://github.com/iProov/flutter/wiki/Upgrade-Guide#upgrading-to-v30) for detailed instructions on how to upgrade to this new version.

### Flutter

* Cancelling all subscriptions to the `Stream<IProovEvent>` returned from `IProov.launch()` will now cancel any ongoing claim.
* `Options` has been overhauled to support the new SDK options in iOS v10 and Android v8 respectively.
* Fixed an issue where internal plugin errors would not be properly surfaced to the app.

### iOS

* Upgraded SDK to [v10.1.1](https://github.com/iProov/ios/releases/tag/10.1.1).
* Fixed an issue where custom fonts would crash on two consecutive launches.

### Android

* Upgraded SDK to [v8.1.0](https://github.com/iProov/android/releases/tag/v8.1.0).
* Fixed an issue where custom fonts would not be applied correctly.

### API Client

* Improved exception handling.
* The API Client now requires Dart 2.17+.

### Example app

* The example app now builds with sound null safety.

## 2.0.0

iProov SDK Face Flutter SDK v2.0.0 is a major update which includes a number of improvements and breaking changes.

Please consult the [Upgrade Guide](https://github.com/iProov/flutter/wiki/Upgrade-Guide#upgrading-to-v20) for detailed instructions on how to upgrade to this new version.

### Flutter

* `IProov.launch()` now returns a `Stream<IProovEvent>` rather than using callbacks.
* `Options` are now built from `const` constructors rather than setting individual properties.
* Added comprehensive documentation to `Options`.
* Added the following new options, supported in the latest SDK versions:
  * `UiOptions.floatingPromptRoundedCorners`
  * `GenuinePresenceAssuranceUiOptions.readyFloatingPromptBackgroundColor`
  * `GenuinePresenceAssuranceUiOptions.notReadyFloatingPromptBackgroundColor`
  * `GenuinePresenceAssuranceUiOptions.readyOverlayStrokeColor`
  * `GenuinePresenceAssuranceUiOptions.notReadyOverlayStrokeColor`
  * `LivenessAssuranceUiOptions.floatingPromptBackgroundColor`
  * `LivenessAssuranceUiOptions.overlayStrokeColor`
* Fixed an issue where specifying custom certificates for pinning would result in a crash.

### iOS

* Upgraded SDK to [v9.5.0](https://github.com/iProov/ios/releases/tag/9.5.0).

### Android

* Upgraded SDK to [v7.5.0](https://github.com/iProov/android/releases/tag/v7.5.0).

### API Client

* The Dart API client is now provided as a separate module, `iproov_api_client`.
* Upgraded [http](https://pub.dev/packages/http) to v0.13.4.
* Added support for the `/validate` API call.

### Example App

* Fixed an issue where the Android example app wouldn't build due to an error relating to Android embedding.

## 1.1.1

### iOS

* Upgraded SDK to [v9.3.2](https://github.com/iProov/ios/releases/tag/9.3.2).

## 1.1.0

### iOS

* Upgraded SDK to [v9.3.1](https://github.com/iProov/ios/releases/tag/9.3.1).

### Android

* Upgraded SDK to [v7.3.0](https://github.com/iProov/android/releases/tag/v7.3.0).

## 1.0.0

We're pleased to announce that the iProov Face Flutter SDK is now production-ready!

### Flutter

* Added `floatingPromptEnabled` to `UiOptions`.
* Renamed `footerTextColor` to `promptTextColor` in `UiOptions`.
* Removed `font` and `fontResource` from `UiOptions`. Use `fontPath` instead, which is now cross-platform.

### iOS

* Upgraded SDK to [v9.3.0](https://github.com/iProov/ios/releases/tag/9.3.0).
* Updated installation instructions for Cocoapods.
* Added support for custom fonts.

### Android

* Upgraded SDK to [v7.2.0](https://github.com/iProov/android/releases/tag/v7.2.0).
* Added support for custom fonts.

## 0.2.0

### Flutter

* All parameters to `IProov.launch()` are now named parameters.
* API key and secret for the Example app should now be set in `api_keys.dart`.
* Added `flutter_lints` dependency to package and example app.
* Added `headerBackgroundColor`, `footerBackgroundColor`, `headerTextColor` and `footerTextColor` to `UiOptions`.
* General improvements to the Example app.
* Improved coding style and formatting.
* Pinning certificates should now be passed as `List<int>` instead of `String` paths.

### iOS

* Upgraded SDK to [v9.2.0](https://github.com/iProov/ios/releases/tag/9.2.0).
* Passing certificates directly as `List<int>` is now supported.
* Error handling improvements.
* `closeButtonImage` is now supported.

### Android

* Upgraded SDK to [v7.1.0](https://github.com/iProov/android/releases/tag/v7.1.0).
* Passing certificates directly as `List<int>` is now supported.
* Error handling improvements.

## 0.1.0

Initial preview release

* iOS SDK [9.0.1](https://github.com/iProov/ios/releases/tag/9.0.1).
* Android SDK [7.0.3](https://github.com/iProov/android/releases/tag/v7.0.3).