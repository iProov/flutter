![iProov: Flexible authentication for identity assurance](https://github.com/iProov/flutter/raw/main/images/banner.jpg)
# iProov Face Flutter SDK

## Introduction

The iProov Face Flutter SDK wraps iProov's native [iOS](https://github.com/iProov/ios) (Swift) and [Android](https://github.com/iProov/android) (Java) SDKs behind a Dart interface for use from within your Flutter iOS or Android app.

We also provide an API Client written in Dart to call our [REST API v2](https://eu.rp.secure.iproov.me/docs.html) from a Flutter app, which can be used from your Flutter app to request tokens directly from the iProov API (note that this is not a secure way of getting tokens, and should only be used for demo/debugging purposes).

### Requirements

- Dart SDK 3.0.0 and above
- Flutter SDK 3.27.0 and above
- iOS 15 and above
- Android API Level 26 (Android 8 Oreo) and above
- Kotlin 1.8.10 and above

## Repository contents

The iProov Flutter SDK is provided via this repository, which contains the following:

- **README.md** - This document
- **example** - A demonstration Flutter App
- **iproov\_api\_client** - The Dart iProov API Client
- **lib** - Folder containing the Flutter (Dart) side of the SDK Plugin
- **android** - Folder containing the Android (Kotlin) native side of the SDK Plugin
- **ios** - Folder containing the iOS (Swift) native side of the SDK Plugin

## Registration

You can obtain API credentials by registering on [iPortal](https://portal.iproov.com).

## Installation

Add the following to your project's `pubspec.yaml` file:

```yaml
dependencies:
  iproov_flutter: ^6.0.0
```

You can then install it with:

```
flutter pub get
```

### iOS installation

You must also add a `NSCameraUsageDescription` to your iOS app's Info.plist, with the reason why your app requires camera access (e.g. “To iProov you in order to verify your identity.”).

## Get started

Once you have a valid token (obtained via the Dart API client or your own backend-to-backend call), you can `launch()` an iProov capture and handle the callback events as they arrive in the `Stream<IProovEvent>`.

```dart
import 'package:iproov_flutter/iproov_flutter.dart';

// Streaming URL provided for example only (substitute as appropriate)
final stream = IProov.launch(streamingUrl: 'wss://eu.rp.secure.iproov.me/ws', token: '< YOUR TOKEN >');
    
stream.listen((event) {

  if (event is IProovEventConnecting) {
    // The SDK is connecting to the server. You should provide an indeterminate progress indicator
    // to let the user know that the connection is taking place.
  
  } else if (event is IProovEventConnected) {
    // The SDK has connected, and the iProov user interface will now be displayed. You should hide
    // any progress indication at this point.
  
  } else if (event is IProovEventProcessing) {
    // The SDK will update your app with the progress of streaming to the server and authenticating
    // the user. This will be called multiple times as the progress updates.
    final progress = event.progress; // Progress between 0.0 and 1.0
    final message = event.message; // Message to be displayed to the user
  
  } else if (event is IProovEventSuccess) {
    // The user was successfully verified/enrolled and the token has been validated.
    // You can access the following properties:
    final frame = result.frame; // An optional image containing a single frame of the user, if enabled for your service provider
  
  } else if (event is IProovEventCanceled) {
    // The user canceled iProov, either by pressing the close button at the top of the screen, or sending
    // the app to the background. (event.canceler == Canceler.user)
    // Or, the app canceled (event.canceler == Canceler.app) by canceling the subscription to the 
    // Stream returned from IProov.launch().
    // You should use this to determine the next step in your flow.
    final canceler = event.canceler;
  
  } else if (event is IProovEventFailure) {
    // The user was not successfully verified/enrolled, as their identity could not be verified,
    // or there was another issue with their verification/enrollment. A list of reasons is provided to understand why the claim failed, where each reason contains two properties:
    // - feedbackCode: A string representation of the feedback code.
    // - description: An informative hint for the user to increase their chances of iProoving successfully next time.

    final reasons = event.reasons
    final frame = event.frame // An optional image containing a single frame of the user, if enabled for your service provider
  
  } else if (event is IProovEventError) {
    // The user was not successfully verified/enrolled due to an error (e.g. lost internet connection).
    // You will be provided with an Exception (see below).
    // It will be called once, or never.
    final error = event.error // IProovException provided by the SDK
  }
  
});
```

### UI Event (Optional)

This feature was implemented in response to a specific request, but its applicability to other users may not be useful.

To monitor iProov UI lifecycle of a claim and receive the result, you collect from the `IProov.uiEvent()`.

```dart

IProov.uiEvent().listen((uiEvent) {
    if (uiEvent is IProovUIEventNotStarted) {
      // Called before the iProov user interface is displayed.
    } else if (uiEvent is IProovUIEventStarted) {
      // Called when the iProov user interface is displayed.
    } else if (uiEvent is IProovUIEventEnded) {
      // Called when the iProov user interface is dismissed.
    }
});
```

👉 You should now familiarize yourself with the following resources:

-  [iProov Face iOS SDK documentation](https://github.com/iProov/ios)
-  [Android Face Android SDK documentation](https://github.com/iProov/android)

These repositories provide comprehensive documentation about the available customization options and other important details regarding the SDK usage.


### Canceling the SDK

Under normal circumstances, the user will be in control of the completion of the iProov scan, i.e. they will either complete the scan, or use the close button to cancel. In some cases, you (the integrator) may wish to cancel the iProov scan programmatically, for example in response to a timeout or change of conditions in your app.

The scan can now be closed doing `IProov.cancel()`. Also canceling all subscriptions to the `Stream<IProovEvent>` returned from `IProov.launch()` will cancel any ongoing claim.

Example:

```dart
final stream = IProov.launch(streamingUrl: 'wss://eu.rp.secure.iproov.me/ws', token: '< YOUR TOKEN >');
    
final subscription = stream.listen((event) { ... });

subscription.cancel();
```

## Options

The `Options` class allows iProov to be customized in various ways. These can be specified by passing the optional `options:` named parameter in `IProov.launch()`.

Most of these options are common to both Android and iOS, however, some are Android-only.

For full documentation, please read the respective [iOS](https://github.com/iProov/ios#options) and [Android](https://github.com/iProov/android#customize-the-user-experience) native SDK documentation.

A summary of the support for the various SDK options in Flutter is provided below. All options are nullable and any options not set will default to their platform-defined default value.

| Option                         | Type                                              | iOS | Android |
|--------------------------------|---------------------------------------------------|---|---|
| `filter`                       | `Filter?` [(See filter options)](#filter-options) | ✅ | ✅ |
| `titleTextColor`               | `Color?`                                          | ✅ | ✅ |
| `promptTextColor`              | `Color?`                                          | ✅ | ✅ |
| `closeButtonTintColor`         | `Color?`                                          | ✅ | ✅ |
| `closeButtonImage`             | `Image?`                                          | ✅ | ✅ |
| `title`                        | `String?`                                         | ✅ | ✅ |
| `fontPath` (*)                 | `String?`                                         | ✅  | ✅ |
| `logoImage`                    | `Image?`                                          | ✅ | ✅ |
| `promptBackgroundColor`        | `Color?`                                          | ✅ | ✅ |
| `promptRoundedCorners`         | `bool?`                                           | ✅ | ✅ |
| `surroundColor`                | `Color?`                                          | ✅ | ✅ |
| `certificates`                 | `List<String>?`                                   | ✅ | ✅ |
| `timeout`                      | `Duration?`                                       | ✅ | ✅ |
| `enableScreenshots`            | `bool?`                                           |  | ✅ |
| `orientation`                  | `Orientation?`                                    |  | ✅ |
| `headerBackgroundColor`        | `Color?`                                          | ✅ | ✅ |
| `disableExteriorEffects`       | `bool?`                                           | ✅ | ✅ |
| **`genuinePresenceAssurance`** | `GenuinePresenceAssuranceOptions?`                |  |  |
| ↳ `readyOvalStrokeColor`       | `Color?`                                          | ✅ | ✅ |
| ↳ `notReadyOvalStrokeColor`    | `Color?`                                          | ✅ | ✅ |
| ↳ `controlYPosition`           | `bool?`                                           | ✅ | ✅ |
| ↳ `controlXposition`           | `bool?`                                          | ✅ | ✅ |
| ↳ `scanningPrompts`            | `bool?`                                          | ✅ | ✅ |
| **`livenessAssurance`**        | `LivenessAssuranceOptions?`                       |  |  |
| ↳ `ovalStrokeColor`            | `Color?`                                          | ✅ | ✅ |
| ↳ `completedOvalStrokeColor`   | `Color?`                                          | ✅ | ✅ |

(*) Fonts should be added to your Flutter app (TTF or OTF formats are supported). Note that the font filename must match the font name.

Example:
```dart
const options = Options(fontPath: 'fonts/Lobster-Regula.ttf');
```

### Filter Options

The SDK supports two different camera filters:

#### `LineDrawingFilter`

`LineDrawingFilter` is iProov's traditional "canny" filter, which is available in 3 styles: `.shaded` (default), `.classic` and `.vibrant`.

The `foregroundColor` and `backgroundColor` can also be customized.

Example:

```dart
const options = Options(
      filter: LineDrawingFilter(
          style: LineDrawingFilterStyle.vibrant,
          foregroundColor: Colors.black,
          backgroundColor: Colors.white
      ),
    );
```

#### `NaturalFilter`

`NaturalFilter` provides a more direct visualization of the user's face and is available in 2 styles: `.clear` (default) and `.blur`.

Example:

```dart
const options = Options(
      filter: NaturalFilter(
          style: NaturalFilterStyle.clear
      ),
    );
```

> **Note**: `NaturalFilter` is available for Liveness Assurance claims only. Attempts to use `NaturalFilter` for Genuine Presence Assurance claims will result in an error.

## Handling errors

All errors from the native SDKs are re-mapped to Flutter exceptions:

| Exception                         | iOS | Android | Description                                                                                                                      |
| --------------------------------- | --- | ------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `CaptureAlreadyActiveException`   | ✅   | ✅       | An existing iProov capture is already in progress. Wait until the current capture completes before starting a new one.           |
| `NetworkException`                    | ✅   | ✅       | An error occurred with the video streaming process. Consult the `message` value for more information.                            |
| `CameraPermissionException`           | ✅   | ✅       | The user disallowed access to the camera when prompted. You should direct the user to re-enable camera access.                   |
| `ServerException`                 | ✅   | ✅       | A server-side error/token invalidation occurred. The associated `message` will contain further information about the error.      |
| `UnexpectedErrorException`        | ✅   | ✅       | An unexpected and unrecoverable error has occurred. These errors should be reported to iProov for further investigation.         |
| `UnsupportedDeviceException`         |✅   | ✅         | Device is not supported.|
| `ListenerNotRegisteredException`  |     | ✅       | The SDK was launched before a listener was registered.                                                                           |
| `MultiWindowUnsupportedException` |     | ✅       | The user attempted to iProov in split-screen/multi-screen mode, which is not supported.                                          |
| `CameraException`                 |     | ✅       | An error occurred acquiring or using the camera. This could happen when a non-phone is used with/without an external/USB camera. |
| `InvalidOptionsException`         |     | ✅       | An error occurred when trying to apply your options.|
| `UserTimeoutException`         |✅   |          | The user has taken too long to complete the claim.|

## API Client

The Dart API Client (`iproov_api_client`) provides a convenient wrapper to call iProov's REST API v2 from your Flutter app. It is a useful tool to assist with testing, debugging and demos, but should not be used in production mobile apps. You can also use this code as a reference for your back-end implementation to perform server-to-server calls.

The Dart API client package can be found in the `iproov_api_client` folder. You can add it to your project as follows:

```yaml
  iproov_api_client:
    git:
      url: git@github.com:iProov/flutter-sdk.git
      path: iproov_api_client
```

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
  secret: '< YOUR SECRET >',
);

final token = await apiClient.getToken(
  assuranceType: AssuranceType.genuinePresenceAssurance,
  claimType: ClaimType.enrol,
  userId: "name@example.com",
);
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
