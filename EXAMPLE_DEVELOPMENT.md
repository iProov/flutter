# Example App Development Guide

Guide to building and running the iProov Flutter SDK example app locally.

## Prerequisites

- Flutter SDK 3.27.0+
- Xcode (for iOS)
- Android Studio (for Android)

## First-time setup

1. From the repository root, fetch the native SDK binaries:
   ```bash
   ./scripts/fetch-dependencies.sh
   ```
   This deletes any existing binaries, downloads fresh copies with SHA-256 verification, and runs the verify script. Run it again whenever `sdk-versions.properties` changes, or if you fetched the binaries before the iOS framework moved to `ios/iproov_flutter/Frameworks/`.
2. Copy the credentials file and fill in your `hostname`, `apiKey` and `secret` from the [iProov portal](https://portal.iproov.com/):
   ```bash
   cp example/lib/credentials.example.dart example/lib/credentials.dart
   ```

## Running the example

From `example/`:

- From the command line: `flutter run -d android` or `flutter run -d ios`.
- From Xcode:
  1. Run `flutter build ios --config-only`.
  2. Open `ios/Runner.xcworkspace` in Xcode and run the app.

  Run step 1 again after any `flutter clean`. Otherwise Xcode reports "Missing package product 'FlutterGeneratedPluginSwiftPackage'", and that `Generated.xcconfig` and the CocoaPods files are missing.

## Building the example with Swift Package Manager

From `example/`:

1. If the example is open in Xcode, close it.
2. If your Flutter version is below 3.44, turn Swift Package Manager on. This applies to every Flutter project on your machine.
   ```bash
   flutter config --enable-swift-package-manager
   ```
3. Remove the previous build and set up the iOS project again:
   ```bash
   flutter clean
   flutter build ios --config-only
   ```
4. Check that `ios/Podfile.lock` doesn't list `iproov_flutter`.
5. Run the example with `flutter run -d ios` or from Xcode.

## Building the example with CocoaPods

From `example/`:

1. If the example is open in Xcode, close it.
2. Turn Swift Package Manager off:
   ```bash
   flutter config --no-enable-swift-package-manager
   ```
3. Remove the previous build and set up the iOS project again:
   ```bash
   flutter clean
   flutter build ios --config-only
   ```
4. Check that `ios/Podfile.lock` lists `iproov_flutter`.
5. Run the example with `flutter run -d ios` or from Xcode.

## Changes not to commit

Building the example can change committed files that must stay as they are, so the example keeps building on Flutter 3.27, the oldest version we support:

- With CocoaPods, Flutter can rewrite `ios/Podfile.lock` and `ios/Runner.xcodeproj/project.pbxproj`. Restore them with `git checkout -- ios/Podfile.lock ios/Runner.xcodeproj/project.pbxproj`.
- Flutter 3.38 and above rewrites `ios/Runner/AppDelegate.swift` and `ios/Runner/Info.plist` for the UIScene lifecycle. The new `AppDelegate.swift` doesn't build on earlier versions.

## Files Xcode needs

Xcode builds the example from files that Flutter generates and git ignores: `Generated.xcconfig`, the CocoaPods files, and the `FlutterGeneratedPluginSwiftPackage` package in `example/ios/Flutter/ephemeral/`. `flutter build ios --config-only` creates them without building the app. The example's Xcode project uses that package with CocoaPods too, because Flutter keeps the Swift Package Manager setup in the project when CocoaPods is used ([Flutter docs](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers#how-to-turn-off-swift-package-manager)). With CocoaPods the package is empty.

With Swift Package Manager, `flutter pub get` is not enough. It writes the package with a minimum of iOS 13.0, below the plugin's iOS 16.0, so Xcode can't resolve it. Only `flutter build` and `flutter run` set it to the example's minimum. This is a known Flutter issue ([flutter/flutter #162196](https://github.com/flutter/flutter/issues/162196)), and `config-only` is the step [Flutter's docs give](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers#how-to-use-a-swift-package-manager-flutter-plugin-that-requires-a-higher-os-version) for it.

## Bumping native SDK versions

1. Update `IOS_VERSION` and/or `ANDROID_VERSION` in `sdk-versions.properties`
2. Run `./scripts/fetch-dependencies.sh` (cleans old binaries, fetches new ones, verifies)
3. Build and test both platforms
