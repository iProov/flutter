![iProov: Flexible authentication for identity assurance](images/banner.jpg)
# iProov Biometrics Flutter SDK Plugin v0.1.0

## Table of contents

- [Introduction](#introduction)
- [Repository contents](#repository-contents)
- [Registration](#registration)
- [Installation](#installation)
- [Get started](#get-started)
- [Options](#options)
- [String localization & customization](#string-localization--customization)
- [Handling failures & errors](#handling-failures--errors)
- [Alternative face detectors](#alternative-face-detectors)
- [Sample code](#sample-code)
- [Help & support](#help--support)

## Introduction

The iProov Flutter SDK Plugin enables you to integrate iProov into your Flutter project and deploy onto Android and iOS platforms with native support for iProov Biometric features behind a Dart interface.

It supports both **Genuine Presence Assurance** and **Liveness Assurance** methods of face verification. Which method gets used depends on the token request and response. See [Get started](#get-started).

## Repository contents

The iProov Flutter SDK is provided via this repository, which contains the following:

- **README.md** - This document
- **LICENSE.txt** - License for this code
- **LICENSES.md** - References to the iProov native SDKs' LICENSE.md files indicating third party licenses
- **example** - Folder containing a demonstration Flutter App containing a Dart iProov Api Client implementation (for demonstrations only)
- **lib** - Folder containing the Flutter (Dart) side of the SDK Plugin
- **android** - Folder containing the Android (Kotlin) side of the SDK Plugin
- **ios** - Folder containing the iOS (Swift) side of the SDK Plugin

## Registration

You can obtain API credentials by registering on the [iProov Partner Portal](https://portal.iproov.net).

## Installation

Add the following to your project's `pubspec.yml` file. As you can see, our plugin is published via our public GitHub repository.

```
dependencies:
  iproov: ^0.1.0
    git:
      url: git@github.com:iProov/flutter.git
```

## Get started

To use iProov to enrol or verify a user it is necessary to follow these steps:

### Obtain a token

Before being able to launch iProov, you need to get a token to iProov against. There are 2 different token types:

1. A **verify** token - for logging-in an existing user
2. An **enrol** token - for registering a new user

In a production app, you normally would want to obtain the token via a server-to-server back-end call.
For the purposes of on-device demos/testing, we provide Dart sample code for obtaining tokens via [iProov API v2](https://eu.rp.secure.iproov.me/docs.html) in the `api-client.dart` file inside the example app.

### Launching and handling responses

Once you have a valid token, you can `launch()` an iProov capture using the following:

```dart
import 'package:iproov/iproov.dart';

IProov.events.listen(handleResponse);
IProov.launch(url, token, options);
```

The `launch()` function takes three parameters (the third is optional):

1. `url` - this is the url of the server handling your authentication
2. `token` - was obtained from an initial call via your server (or using `api-client.dart` for testing ONLY)
3. `options` - these are all the configurations that can be applied to customize iProov. You can read up on the way they are presented in Dart [below](#options), and in greater detail in the respective [Android](https://github.com/iProov/android) and [iOS](https://github.com/iProov/ios) native SDK documentation.

The `events` field represents a `Stream<IProovEvent>` indicating the progress of the IProov scan.
In the example, a function called `handleResponse` is used to handle all the responses. There are many types of response and each one is represented by a subclass of `IProovEvent`.

### Responses

The `IProovEvent` subclasses represent the various states an iProov capture goes through from `launch()` (making connections), via the UI (showing progress), and after the UI has finished (more progress then a single terminal event).

After `launch()` iProov goes through two stages before displaying the UI and these are repesented by `IProovEventConnecting` and then `IProovEventConnected`.

Once the UI is displayed, iProov begins sending a sequence of `IProovEventProgress` events. These have a `progress` value from 0 to 1 and a human readable `message`. These events can continue after the UI has ended.

iProov can terminate in one of four ways:

1. `IProovEventCancelled` - the user cancelled, by pressing back or moving to another app.
2. `IProovEventError` - if there was an unrecoverable error such as a network failure.
3. `IProovEventFailure` - if the iProov was unsuccessful for many reasons. These are outlined in detail in the respective [Android](https://github.com/iProov/android#handling-failures--errors) and [iOS](https://github.com/iProov/ios#handling-failures--errors) native SDK documentation. This usually means that the face was either not verified or the conditions were not met to determine that a real face was seen.
4. `IProovEventSuccess` - when iProov successfully accepts a new face or verifies it as a real match.

### Important notes

> **⚠️ SECURITY NOTICE:** You should never use iProov as a local authentication method. You cannot rely on the fact that the success result was returned to prove that the user was authenticated or enrolled successfully (it is possible the iProov process could be manipulated locally by a malicious user). You can treat the success callback as a hint to your app to update the UI, etc. but you must always independently validate the token server-side (using the validate API call) before performing any authenticated user actions.

## Options

The `Options` allow iProov to be customized: for example by changing the UI (colors, fonts, icon, face representation, scan line), defining the network access, selecting a [face detector](#alternative-face-detectors), etc.

Most of these options are common to both Android and iOS, however, some are platform specific (for example Android resources). For a full description, please read the respective [Android](https://github.com/iProov/android#options) and [iOS](https://github.com/iProov/ios#options) native SDK documentation.

### Android

These examples are in the example app and demonstrate the differences in Android handling of options.

```dart
// For font assets in the android/app/src/main/assets folder we just give the full name plus extension
options.ui.fontPath = "montserrat_regular.ttf";

// For font resources in the android/app/src/main/res/font folder we just give the name without extension
options.ui.fontResource = "montserrat_bold";

// For logo, only logoImageResource is available, in the android/app/src/main/res/drawable folder we just give the name without extension
options.ui.logoImageResource = "ic_launcher";

// For certificates you add them to the android/app/src/main/res/raw folder and reference them here like below (no extension)
options.network.certificates = [ "raw/customer__certificate" ];

// You can just use Flutter/Dart Colors for all Color types
options.ui.lineColor = Colors.red;
```

To address Android specific options, such as font and icon resources, we have to do something different in Flutter. For example, instead of passing an `R` integer such as `R.font.montserrat_bold`, we just pass the String `"montserrat_bold"` into `options.ui.fontResource` and this then references a font in the `res/font/` folder of the android module of your app. 

Similarly for Drawables, for example, `options.ui.logoImageResource = "ic_launcher";`

When using `options.ui.fontPath` then the ttf file will be expected in the `android/app/src/main/assets` folder of the android module of your app. However, this time the extension name is required: `options.ui.fontPath = "montserrat_regular.ttf";`

Similary for the certificates, although no extension is required. Since there can be many certificates then an array of Strings is expected. Certificate files are expected in the `android/app/src/main/res/raw` folder of the android module of your app. For example, `options.network.certificates = [ "raw/customer__certificate" ];`

Colors are all Flutter based. For example, `options.ui.lineColor = Colors.red;`

## String localization & customization

Please read the respective [Android](https://github.com/iProov/android#string-localization--customization) and [iOS](https://github.com/iProov/ios#localization) native SDK documentation.

### Android

With Android, any alternate strings.xml will need to be put into the android module of your app. 

## Handling failures & errors

Please read the respective [Android](https://github.com/iProov/android#handling-failures--errors) and [iOS](https://github.com/iProov/ios#handling-failures--errors) native SDK documentation.

### Android

In Android, the `IProovEventError` event is triggered by an exception represented by a Java `Exception` called `IProovException`. This cannot readily be passed over to Dart and so only the String representation is provided in the field `exception`.

## Alternative face detectors

### Android

The Android SDK supports a classic face detector built in and two others: Blazeface and MLKit - to find out more, and to help you decide whether to use them over the classic, have a look at the [Android documentation](https://github.com/iProov/android-sdk#alternative-face-detectors).

To add MLKit, you need to add this to the build.gradle in the android module of your app.

```
dependencies {
    implementation "com.iproov.sdk:iproov-mlkit:6.3.1"
}
```

Similarly to add Blazeface, you need to add this to the build.gradle in the android module of your app.

```
dependencies {
    implementation "com.iproov.sdk:iproov-blazeface:6.3.1"
}
```

Once you have added one or both of these you can select which to use in the [Options](#options).

## Sample code

For an out-of-the-box demonstration, the `example` app in the repo shows how to use iProov. It also includes a Dart version of our Api Client, which allows the client (under strictly non-production apps) to obtain the relevant token to start an iProov Capture - in a production app the Api Client functionality should be implemented on your servers for secure server to server communications. The client is thus never considered to be secure.

## Help & support

You may find your question is answered in our FAQs: [Android](https://github.com/iProov/android/wiki/Frequently-Asked-Questions) [iOS](https://github.com/iProov/ios/wiki/Frequently-Asked-Questions) or one of our other Wiki pages: [Android](https://github.com/iProov/android/wiki) [iOS](https://github.com/iProov/ios/wiki).

For further help with integrating the SDK, please contact [support@iproov.com](mailto:support@iproov.com).
