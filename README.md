![iProov: Flexible authentication for identity assurance](images/banner.jpg)
# iProov Biometrics Flutter SDK (Preview)

## Table of contents

- [Introduction](#introduction)
- [Repository contents](#repository-contents)
- [Registration](#registration)
- [Installation](#installation)
- [Get started](#get-started)
- [Options](#options)
- [Sample code](#sample-code)
- [Help & support](#help--support)

## Introduction

The iProov Biometrics Flutter SDK wraps iProov's existing native [iOS](https://github.com/iProov/ios) (Swift) and [Android](https://github.com/iProov/android) (Java) SDKs behind a Dart interface for use from within your Flutter app.

We also provide an API Client written in Dart to call our [REST API v2](https://eu.rp.secure.iproov.me/docs.html) from a Flutter app, which can be used from your Flutter app to request tokens directly from the iProov API (note that this is not a secure way of getting tokens, and should only be used for demo/debugging purposes).

### Preview

The iProov Biometrics Flutter SDK is currently in preview, which means that there may be missing/broken functionality, and the API is still subject to change. Please [contact us](mailto:support@iproov.com) to provide your feedback regarding the iProov Biometrics Flutter SDK Preview.

## Repository contents

The iProov Flutter SDK is provided via this repository, which contains the following:

- **README.md** - This document
- **example** - A demonstration Flutter App along with the Dart iProov API Client
- **lib** - Folder containing the Flutter (Dart) side of the SDK Plugin
- **android** - Folder containing the Android (Kotlin) native side of the SDK Plugin
- **ios** - Folder containing the iOS (Swift) native side of the SDK Plugin

## Registration

You can obtain API credentials by registering on the [iProov Partner Portal](https://portal.iproov.net).

## Installation

Add the following to your project's `pubspec.yml` file:

```
dependencies:
  iproov_flutter: ^0.1.0
    git:
      url: git@github.com:iProov/flutter.git
```

### iOS installation

You must also add a `NSCameraUsageDescription` to your iOS app's Info.plist, with the reason why your app requires camera access (e.g. “To iProov you in order to verify your identity.”)

## Get started

To use iProov to enrol or verify a user it is necessary to follow these steps:

Once you have a valid token (obtained via the Dart API client or your own backend-to-backend call), you can `launch()` an iProov capture using the following:

```dart
import 'package:iproov_flutter/iproov_flutter.dart';

IProov.events.listen((event) {
  if (event is IProovEventConnecting) {
	// The SDK is connecting to the server. You should provide an indeterminate progress indicator
	// to let the user know that the connection is taking place.
  
  } else if (event is IProovEventConnected) {
	// The SDK has connected, and the iProov user interface will now be displayed. You should hide
	// any progress indication at this point.
  
  } else if (event is IProovEventProgress) {
	// The SDK will update your app with the progress of streaming to the server and authenticating
	// the user. This will be called multiple time as the progress updates.
  
  } else if (event is IProovEventSuccess) {
	// The user was successfully verified/enrolled and the token has been validated.
	// You can access the following properties:
	var token = result.token; // The token passed back will be the same as the one passed in to the original call
	var frame = result.frame; // An optional image containing a single frame of the user, if enabled for your service provider
  
  } else if (event is IProovEventCancelled) {
	// The user cancelled iProov, either by pressing the close button at the top right, or sending
	// the app to the background.
  
  } else if (event is IProovEventFailure) {
	// The user was not successfully verified/enrolled, as their identity could not be verified,
	// or there was another issue with their verification/enrollment. A reason (as a string)
	// is provided as to why the claim failed, along with a feedback code from the back-end.
	var feedbackCode = event.feedbackCode;
	var reason = event.reason;
  
  } else if (event is IProovEventError) {
	// The user was not successfully verified/enrolled due to an error (e.g. lost internet connection).
	// You will be provided with an NSError. You can check the error code against the IPErrorCode constants
	// to determine the type of error.
	// It will be called once, or never.
  }
});

IProov.launch(streamingUrl, token, options);
```

👉 You should now familiarise yourself with the following resources:

-  [iProov Biometrics iOS SDK documentation](https://github.com/iProov/ios)
-  [Android Biometrics Android SDK documentation](https://github.com/iProov/android)

which provide comprehensive details about the available customization options and other important details regarding the iOS SDK usage.

## Options

The `Options` class allows iProov to be customized in various ways.

Most of these options are common to both Android and iOS, however, some are platform-specific (for example, iOS has a close button but Android does not).

For full documentation, please read the respective [Android](https://github.com/iProov/android#options) and [iOS](https://github.com/iProov/ios#options) native SDK documentation.

A summary of the support for the various SDK options in Flutter is summarised below:

| Syntax | iOS | Android |
| --- | --- | --- |
| **`Options.ui.`** |  |  |
| `filter` | ✅ | ✅ |
| `lineColor` | ✅ | ✅ | 
| `backgroundColor` | ✅ | ✅ |
| `title` | ✅ | ✅ |
| `fontPath` |  | ⚠️ (1) |
| `fontResource` |  | ⚠️ (1) |
| `font` | ⚠️ (1) |  |
| `logoImage` | ✅ | ✅ |
| `closeButtonImage` | ✅ |  |
| `closeButtonTintColor` | ✅ |  |
| `enableScreenshots` |  | ✅  |
| `orientation` |  | ✅ |
| `activityCompatibilityRequestCode` |  | ✅ |
| **`Options.ui.genuinePresenceAssurance.`** |  |  |
| `autoStartDisabled` | ✅ | ✅ |
| `notReadyTintColor` | ✅ | ✅ |
| `readyTintColor` | ✅ | ✅ |
| `progressBarColor` | ✅ | ✅ |
| **`Options.ui.livenessAssurance.`** |  |  |
| `primaryTintColor` | ✅ | ✅ |
| `secondaryTintColor` | ✅ | ✅ |
| **`Options.network.`** |  |  |
| `certificates` | ⚠️ (2) | ⚠️ (2) |
| `timeout` | ✅ | ✅ |
| `path` | ✅ | ✅ |
| **`Options.capture.`** |  |  |
| `camera` |   | ✅ |
| `faceDetector` |  | ✅ |
| **`Options.capture.genuinePresenceAssurance.`** |  |  |
| `maxPitch` | ✅ (3) | ✅ (3) |
| `maxYaw` | ✅ (3) | ✅ (3) |
| `maxRoll` | ✅ (3) | ✅ (3) |

(1) There are currently different ways of setting fonts on iOS & Android. Fonts should be added to the respective iOS app bundle or Android project (`android/app/src/main/res/font`) and can then be set by name via this API. This is due to be revised in a future release.

(2) The certificates must be added to the respective iOS app bundle or Android project (`android/app/src/main/res/raw`) and the respective native option can then be set for the current platform (via `Platform.isAndroid` or `Platform.isIOS`). This is set to be improved in a future release.

(3) This is an advanced option and not recommended for general usage. If you wish to use this option, contact iProov for for further details.

## Sample code

For a simple iProov experience that is ready to run out-of-the-box, check out the Flutter example project which also makes use of the Dart API Client.

> NOTE: iProov is not supported on the iOS or Android simulator, you must use a physical device in order to iProov.

## Help & support

You may find your question is answered in the documentation of our native SDKs:

- iOS - [Documentation](https://github.com/iProov/ios), [FAQs](https://github.com/iProov/ios/wiki/Frequently-Asked-Questions)
- Android - [Documentation](https://github.com/iProov/android), [FAQs](https://github.com/iProov/android/wiki/Frequently-Asked-Questions)

For further help with integrating the SDK, please contact [support@iproov.com](mailto:support@iproov.com).
