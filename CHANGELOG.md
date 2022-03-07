# iProov Biometrics Flutter SDK

## 1.0.0

The iProov Biometrics Flutter SDK is now approved for use in production.

### Flutter

* Added `floatingPromptEnabled` to `UiOptions`.
* Renamed `footerTextColor` to `promptTextColor` in `UiOptions`.

### iOS

* Upgraded SDK to [v9.3.0](https://github.com/iProov/ios/releases/tag/9.3.0).
* Updated installation instructions for Cocoapods.

### Android

* Upgraded SDK to [v7.2.0](https://github.com/iProov/android/releases/tag/v7.2.0).

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

* Upgraded SDK to v9.2.0.
* Passing certificates directly as `List<int>` is now supported.
* Error handling improvements.
* `closeButtonImage` is now supported.

### Android

* Upgraded SDK to v7.1.0.
* Passing certificates directly as `List<int>` is now supported.
* Error handling improvements.

## 0.1.0

Initial preview release

* iOS SDK 9.0.1
* Android SDK 7.0.3