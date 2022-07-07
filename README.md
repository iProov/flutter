![iProov: Flexible authentication for identity assurance](https://github.com/iProov/flutter/raw/main/images/banner.jpg)
# iProov Biometrics Flutter SDK

## Table of contents

- [Introduction](#introduction)
- [Repository contents](#repository-contents)
- [Registration](#registration)
- [Installation](#installation)
- [Get started](#get-started)
- [Options](#options)
- [Handling errors](#handling-errors)
- [API Client](#api-client)
- [Sample code](#sample-code)
- [Help & support](#help--support)

## Introduction

The iProov Biometrics Flutter SDK wraps iProov's native [iOS](https://github.com/iProov/ios) (Swift) and [Android](https://github.com/iProov/android) (Java) SDKs behind a Dart interface for use from within your Flutter iOS or Android app.

We also provide an API Client written in Dart to call our [REST API v2](https://eu.rp.secure.iproov.me/docs.html) from a Flutter app, which can be used from your Flutter app to request tokens directly from the iProov API (note that this is not a secure way of getting tokens, and should only be used for demo/debugging purposes).

### Requirements

- Dart SDK 2.12 and above
- Flutter SDK 1.20 and above
- iOS 10 and above
- Android API Level 21 (Android 5 Lollipop) and above

## Repository contents

The iProov Flutter SDK is provided via this repository, which contains the following:

- **README.md** - This document
- **example** - A demonstration Flutter App
- **iproov\_api\_client** - The Dart iProov API Client
- **lib** - Folder containing the Flutter (Dart) side of the SDK Plugin
- **android** - Folder containing the Android (Kotlin) native side of the SDK Plugin
- **ios** - Folder containing the iOS (Swift) native side of the SDK Plugin

## Registration

You can obtain API credentials by registering on the [iProov Partner Portal](https://portal.iproov.net).

## Installation

Add the following to your project's `pubspec.yml` file:

```yaml
dependencies:
  iproov_flutter: ^2.0.0
```

You can then install it with:

```
flutter pub get
```

### iOS installation

There are a couple of extra steps required for iOS:

1. You must also add a `NSCameraUsageDescription` to your iOS app's Info.plist, with the reason why your app requires camera access (e.g. “To iProov you in order to verify your identity.”)

2. Open the Podfile relating to the iOS project (this can be found at the path _ios/Podfile_). Scroll to the bottom of the file and locate the following:

	```ruby
	post_install do |installer|
	  installer.pods_project.targets.each do |target|
	    flutter_additional_ios_build_settings(target)
	  end
	end
	```
	
	This should be changed to:
	
	```ruby
	post_install do |installer|
	  installer.pods_project.targets.each do |target|
	    flutter_additional_ios_build_settings(target)
	    	    
	    if ['iProov', 'Socket.IO-Client-Swift', 'Starscream'].include? target.name
	      target.build_configurations.each do |config|
	        config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
	      end
	    end
	  end
	end
	```

## Get started

Once you have a valid token (obtained via the Dart API client or your own backend-to-backend call), you can `launch()` an iProov capture and handle the callback events as they arrive in the `Stream<IProovEvent>`.

```dart
import 'package:iproov_flutter/iproov_flutter.dart';

// Streaming URL provided for example only (substitute as appropriate)
final stream = IProov.launch(streamingUrl: 'https://eu.rp.secure.iproov.me', token: '< YOUR TOKEN >');
    
stream.listen((event) {

  if (event is IProovEventConnecting) {
    // The SDK is connecting to the server. You should provide an indeterminate progress indicator
    // to let the user know that the connection is taking place.
  
  } else if (event is IProovEventConnected) {
    // The SDK has connected, and the iProov user interface will now be displayed. You should hide
    // any progress indication at this point.
  
  } else if (event is IProovEventProcessing) {
    // The SDK will update your app with the progress of streaming to the server and authenticating
    // the user. This will be called multiple time as the progress updates.
    final progress = event.progress; // Progress between 0.0 and 1.0
    final message = event.message; // Message to be displayed to the user
  
  } else if (event is IProovEventSuccess) {
    // The user was successfully verified/enrolled and the token has been validated.
    // You can access the following properties:
    final token = result.token; // The token passed back will be the same as the one passed in to the original call
    final frame = result.frame; // An optional image containing a single frame of the user, if enabled for your service provider
  
  } else if (event is IProovEventCancelled) {
    // The user cancelled iProov, either by pressing the close button at the top right, or sending
    // the app to the background.
  
  } else if (event is IProovEventFailure) {
    // The user was not successfully verified/enrolled, as their identity could not be verified,
    // or there was another issue with their verification/enrollment. A reason (as a string)
    // is provided as to why the claim failed, along with a feedback code from the back-end.
    final feedbackCode = event.feedbackCode;
    final reason = event.reason;
  
  } else if (event is IProovEventError) {
    // The user was not successfully verified/enrolled due to an error (e.g. lost internet connection).
    // You will be provided with an Exception (see below).
    // It will be called once, or never.
  }
  
});
```

👉 You should now familiarise yourself with the following resources:

-  [iProov Biometrics iOS SDK documentation](https://github.com/iProov/ios)
-  [Android Biometrics Android SDK documentation](https://github.com/iProov/android)

These repositories provide comprehensive documentation about the available customization options and other important details regarding the SDK usage.

## Options

The `Options` class allows iProov to be customized in various ways. These can be specified by passing the optional `options:` named parameter in `IProov.launch()`.

Most of these options are common to both Android and iOS, however, some are Android-only.

For full documentation, please read the respective [iOS](https://github.com/iProov/ios#options) and [Android](https://github.com/iProov/android#options) native SDK documentation.

A summary of the support for the various SDK options in Flutter is provided below. All options are nullable and any options not set will default to their platform-defined default value.

| Option | Type | iOS | Android |
|---|---|---|---|
| **`ui`** | `UiOptions?` |  |  |
| ↳ `filter` | `Filter?` | ✅ | ✅ |
| ↳ `lineColor` | `Color?` | ✅ | ✅ |
| ↳ `backgroundColor` | `Color?` | ✅ | ✅ |
| ↳ `headerBackgroundColor` | `Color?` | ✅ | ✅ |
| ↳ `footerBackgroundColor` | `Color?` | ✅ | ✅ |
| ↳ `headerTextColor` | `Color?` | ✅ | ✅ |
| ↳ `promptTextColor` | `Color?` | ✅ | ✅ |
| ↳ `floatingPromptEnabled` | `bool?` | ✅ | ✅ |
| ↳ `title` | `String?` | ✅ | ✅ |
| ↳ `fontPath` | `String?` | ✅ (1) | ✅ (1) |
| ↳ `logoImage` | `Image?` | ✅ | ✅ |
| ↳ `closeButtonImage` | `Image?` | ✅ | ✅ |
| ↳ `closeButtonTintColor` | `Color?` | ✅ | ✅ |
| ↳ `enableScreenshots` | `bool?` |  | ✅ |
| ↳ `orientation` | `Orientation?` |  | ✅ |
| ↳ `activityCompatibilityRequestCode` | `int?` |  | ✅ |
| ↳ `floatingPromptRoundedCorners` | `bool?` | ✅ | ✅ |
| ↳ **`genuinePresenceAssurance`** | `GenuinePresenceAssuranceUiOptions?` |  |  |
|   ↳ `autoStartDisabled` | `bool?` | ✅ | ✅ |
|   ↳ `notReadyTintColor` | `Color?` | ✅ | ✅ |
|   ↳ `readyTintColor` | `Color?` | ✅ | ✅ |
|   ↳ `progressBarColor` | `Color?` | ✅ | ✅ |
|   ↳ `readyFloatingPromptBackgroundColor` | `Color?` | ✅ | ✅ |
|   ↳ `notReadyFloatingPromptBackgroundColor` | `Color?` | ✅ | ✅ |
|   ↳ `readyOverlayStrokeColor` | `Color?` | ✅ | ✅ |
|   ↳ `notReadyOverlayStrokeColor` | `Color?` | ✅ | ✅ |
| ↳ **`livenessAssurance`** | `LivenessAssuranceUiOptions?` |  |  |
|   ↳ `primaryTintColor` | `Color?` | ✅ | ✅ |
|   ↳ `secondaryTintColor` | `Color?` | ✅ | ✅ |
|   ↳ `floatingPromptBackgroundColor` | `Color?` | ✅ | ✅ |
|   ↳ `overlayStrokeColor` | `Color?` | ✅ | ✅ |
| **`network`** | `NetworkOptions?` |  |  |
| ↳ `certificates` | `List<Uint8List>?` | ✅ | ✅ |
| ↳ `timeout` | `Duration?` | ✅ | ✅ |
| ↳ `path` | `String?` | ✅ | ✅ |
| **`capture`** | `CaptureOptions?` |  |  |
| ↳ `camera` | `Camera?` |  | ✅ |
| ↳ `faceDetector` | `FaceDetector?` |  | ✅ |
| ↳ **`genuinePresenceAssurance`** | `GenuinePresenceAssuranceCaptureOptions?` |  |  |
|   ↳ `maxPitch` | `double?` | ✅ (2) | ✅ (2) |
|   ↳ `maxYaw` | `double?` | ✅ (2) | ✅ (2) |
|   ↳ `maxRoll` | `double?` | ✅ (2) | ✅ (2) |

(1) Fonts should be added to your Flutter app (TTF or OTF formats are supported). You can then set (for example) `options.ui.fontPath = 'fonts/Lobster-Regula.ttf'` - note that the font filename must match the font name.

(2) This is an advanced option and not recommended for general usage. If you wish to use this option, contact iProov for for further details.

Example:

```dart
const options = Options(
    ui: UiOptions(
        title: 'Example',
        floatingPromptEnabled: true,
        genuinePresenceAssurance: GenuinePresenceAssuranceUiOptions(
            autoStartDisabled: true,
            notReadyTintColor: Colors.grey,
            readyTintColor: Colors.green,
            progressBarColor: Colors.blue)));
```

## Handling errors

All errors from the native SDKs are re-mapped to Flutter exceptions:

| Exception                         | iOS | Android | Description                                                                                                                      |
| --------------------------------- | --- | ------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `CaptureAlreadyActiveException`   | ✅   | ✅       | An existing iProov capture is already in progress. Wait until the current capture completes before starting a new one.           |
| `NetworkError`                    | ✅   | ✅       | An error occurred with the video streaming process. Consult the `message` value for more information.                            |
| `CameraPermissionError`           | ✅   | ✅       | The user disallowed access to the camera when prompted. You should direct the user to re-enable camera access.                   |
| `ServerException`                 | ✅   | ✅       | A server-side error/token invalidation occurred. The associated `message` will contain further information about the error.      |
| `UnexpectedErrorException`        | ✅   | ✅       | An unexpected and unrecoverable error has occurred. These errors should be reported to iProov for further investigation.         |
| `ListenerNotRegisteredException`  |     | ✅       | The SDK was launched before a listener was registered.                                                                           |
| `MultiWindowUnsupportedException` |     | ✅       | The user attempted to iProov in split-screen/multi-screen mode, which is not supported.                                          |
| `CameraException`                 |     | ✅       | An error occurred acquiring or using the camera. This could happen when a non-phone is used with/without an external/USB camera. |
| `FaceDetectorException`           |     | ✅       | An error occurred with the face detector.                                                                                        |
| `InvalidOptionsException`         |     | ✅       | An error occurred when trying to apply your options.                                                                             |

## API Client

The Dart API Client (`iproov_api_client`) provides a convenient wrapper to call iProov's REST API v2 from your Flutter app. It is a useful tool to assist with testing, debugging and demos, but should not be used in production mobile apps. You can also use this code as a reference for your back-end implementation to perform server-to-server calls.

The Dart API client package can be found in the `iproov_api_client` folder.

> **Warning**
>
> Use of the Dart API Client requires providing it with your API secret. **You should never embed your API secret within a production app.**

### Functionality

The Dart API Client supports the following functionality:

- `getToken()` - Get an enrol/verify token.
- `enrolPhoto()` - Perform a photo enrolment (either from an electronic or optical image). The image must be provided as an [`Image`](https://pub.dev/packages/image).
- `enrolPhotoAndGetVerifyToken()` - A convenience method which first gets an enrolment token, then enrols the photo against that token, and then gets a verify token for the user to iProov against.
- `validate()` - Validates a token after the claim has completed.

### Getting a token

The most basic thing you can do with the API Client is get a token to either enrol or verify a user, using either iProov's Genuine Presence Assurance or Liveness Assurance.

This is achieved as follows:

```dart
import 'package:iproov_api_client/iproov_api_client.dart';

final apiClient = const ApiClient(
  baseUrl: 'https://eu.rp.secure.iproov.me/api/v2', // Substitute URL as appropriate
  apiKey: '< YOUR API KEY >',
  secret: '< YOUR SECRET >'
);

final token = await apiClient.getToken(AssuranceType.genuinePresenceAssurance, ClaimType.enrol, "name@example.com");
```

You can then launch the iProov SDK with this token.

## Sample code

For a simple iProov experience that is ready to run out-of-the-box, check out the Flutter example project which also makes use of the Dart API Client.

In the example app folder, copy the `credentials.example.dart` file to `credentials.dart` and add your credentials obtained from the [iProov portal](https://portal.iproov.com/).

> NOTE: iProov is not supported on the iOS or Android simulator, you must use a physical device in order to iProov.

## Help & support

You may find your question is answered in the documentation of our native SDKs:

- iOS - [Documentation](https://github.com/iProov/ios), [FAQs](https://github.com/iProov/ios/wiki/Frequently-Asked-Questions)
- Android - [Documentation](https://github.com/iProov/android), [FAQs](https://github.com/iProov/android/wiki/Frequently-Asked-Questions)

For further help with integrating the SDK, please contact [support@iproov.com](mailto:support@iproov.com).
