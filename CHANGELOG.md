# iProov Biometrics SDK

## 0.2.0

### Flutter

* All parameters to `IProov.launch()` are now named parameters
* API key and secret for the Example app should now be set in `api_keys.dart`
* Added `flutter_lints` dependency to package and example app
* Added `headerBackgroundColor`, `footerBackgroundColor`, `headerTextColor` and `footerTextColor` to `UiOptions`
* General improvements to the Example app
* Improved coding style and formatting
* Pinning certificates should now be passed as `List<int>` instead of `String` paths

### iOS

* Upgraded SDK to v9.2.0
* Passing certificates directly as `List<int>` is now supported
* Error handling improvements
* `closeButtonImage` is now supported

### Android

* Upgraded SDK to v7.1.0
* Passing certificates directly as `List<int>` is now supported
* Error handling improvements

## 0.1.0

Initial preview release

* iOS SDK 9.0.1
* Android SDK 7.0.3