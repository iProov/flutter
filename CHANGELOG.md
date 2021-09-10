# iProov Biometrics SDK

## 0.2.0

* **Breaking**: Made `IProov` constructor public. Now takes `streamingUrl`, `token` and `options` as arguments
* **Breaking**: `launch()` is now an instance method that takes a `IProovEventCallback` and returns a `Future<IProovEvent>`
* **Breaking**: All `Options` classes are now immutable with final properties
* Added `flutter_lints` dependency to package and example app
* Improved coding style
* Improved example app

## 0.1.0

Initial preview release

* iOS SDK 9.0.1
* Android SDK 7.0.3