import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' hide Color;
import 'package:iproov_flutter/enums.dart';

/// Set options for the iProov SDK.
///
/// Most of these options are common to both Android and iOS, however, some are platform-specific.
///
/// All options are nullable and any options not set will default to their platform-defined default value.
class Options {
  /// UI options
  final UiOptions? ui;

  /// Network options
  final NetworkOptions? network;

  /// Capture options
  final CaptureOptions? capture;

  const Options({
    this.ui,
    this.network,
    this.capture,
  });

  Map<String, dynamic> toJson() => {
        'ui': ui?.toJson(),
        'network': network?.toJson(),
        'capture': capture?.toJson(),
      }._withoutNullValues();
}

/// Options relating to the appearance of the iProov user interface.
class UiOptions {
  /// UI options relating specifically to Genuine Presence Assurance (GPA).
  final GenuinePresenceAssuranceUiOptions? genuinePresenceAssurance;

  /// UI options relating specifically to Liveness Assurance (LA).
  final LivenessAssuranceUiOptions? livenessAssurance;

  /// [Filter] to apply for the canny filter effect.
  final Filter? filter;

  /// The [Color] for the canny effect lines.
  final Color? lineColor;

  /// The [Color] to use as the background for the canny effect.
  final Color? backgroundColor;

  /// The [Color] to use as the background for the header bar at the top of the screen.
  final Color? headerBackgroundColor;

  /// The [Color] to use as the background for the footer bar at the bottom of the screen.
  final Color? footerBackgroundColor;

  /// The [Color] to use for the title text that appears in the header.
  final Color? headerTextColor;

  /// The [Color] to use for the prompt text that appears in the footer.
  final Color? promptTextColor;

  /// Whether the prompt text should be floating above the camera preview or appear in the footer bar.
  final bool? floatingPromptEnabled;

  /// A custom title to appear in the header bar at the top of the screen.
  final String? title;

  /// Path to the font to use for the iProov UI. The font must be added to your app (TTF or OTF formats are supported).
  ///
  /// The font filename must match the name of the font.
  final String? fontPath;

  /// A small logo [Image] to display in the header bar at the top of the screen on the right hand side.
  final Image? logoImage;

  /// A custom [Image] to be used for the close button which appears in the header bar at the top of the screen
  /// on the left hand side.
  ///
  /// Note that only the alpha channel of the image is used, you can change the color of the button
  /// using [closeButtonTintColor].
  final Image? closeButtonImage; // Supported in iOS 9.1+

  /// The [Color] to be applied to the [closeButtonImage].
  final Color? closeButtonTintColor;

  /// Whether screenshots should be allowed during the iProov scan process.
  ///
  /// This option only applies to Android.
  final bool? enableScreenshots;

  /// Sets the orientation of the iProov UI.
  ///
  /// This option only applies to Android.
  final Orientation? orientation;

  /// An advanced option which can be used to enable "Activity compatibility mode" on Android with a specified request
  /// code. Use of this option is rarely required.
  ///
  /// For further details, see https://github.com/iProov/android/wiki/Frequently-Asked-Questions#what-is-optionuiactivitycompatibilityrequestcode
  ///
  /// This option only applies to Android.
  final int? activityCompatibilityRequestCode;

  /// Whether the floating prompt (if enabled) should have rounded corners.
  final bool? floatingPromptRoundedCorners;

  const UiOptions({
    this.genuinePresenceAssurance,
    this.livenessAssurance,
    this.filter,
    this.lineColor,
    this.backgroundColor,
    this.headerBackgroundColor,
    this.footerBackgroundColor,
    this.headerTextColor,
    this.promptTextColor,
    this.floatingPromptEnabled,
    this.title,
    this.fontPath,
    this.logoImage,
    this.closeButtonImage,
    this.closeButtonTintColor,
    this.enableScreenshots,
    this.orientation,
    this.activityCompatibilityRequestCode,
    this.floatingPromptRoundedCorners,
  });

  Map<String, dynamic> toJson() => {
        'genuine_presence_assurance': genuinePresenceAssurance?.toJson(),
        'liveness_assurance': livenessAssurance?.toJson(),
        'filter': filter?.stringValue,
        'line_color': lineColor?.hex,
        'background_color': backgroundColor?.hex,
        'header_background_color': headerBackgroundColor?.hex,
        'footer_background_color': footerBackgroundColor?.hex,
        'header_text_color': headerTextColor?.hex,
        'prompt_text_color': promptTextColor?.hex,
        'floating_prompt_enabled': floatingPromptEnabled,
        'title': title,
        'font_path': fontPath,
        'enable_screenshots': enableScreenshots,
        'orientation': orientation?.stringValue,
        'activity_compatibility_request_code': activityCompatibilityRequestCode,
        'close_button_tint_color': closeButtonTintColor?.hex,
        if (logoImage != null) 'logo_image': base64.encode(encodePng(logoImage!)),
        if (closeButtonImage != null) 'close_button_image': base64.encode(encodePng(closeButtonImage!)),
        'floating_prompt_rounded_corners': floatingPromptRoundedCorners,
      }._withoutNullValues();
}

/// Options relating to the appearance of the iProov user interface for GPA claims.
class GenuinePresenceAssuranceUiOptions {
  /// Whether auto-start should be disabled. When disabled, the user must tap the screen to start the scan.
  final bool? autoStartDisabled;

  /// The [Color] to use for the overlay tint when the scan is not ready to start.
  final Color? notReadyTintColor;

  /// The [Color] to use for the overlay tint when the scan is ready to start.
  final Color? readyTintColor;

  /// The [Color] to use for the progress bar (only applies when [autoStartDisabled] is false).
  final Color? progressBarColor;

  /// The [Color] to use for the background of the floating prompt (when enabled) and the scan is ready to start.
  final Color? readyFloatingPromptBackgroundColor;

  /// The [Color] to use for the background of the floating prompt (when enabled) and the scan is not ready to start.
  final Color? notReadyFloatingPromptBackgroundColor;

  /// The [Color] to use for the oval and reticle stroke lines when the scan is ready to start.
  final Color? readyOverlayStrokeColor;

  /// The [Color] to use for the oval and reticle stroke lines when the scan is not ready to start.
  final Color? notReadyOverlayStrokeColor;

  const GenuinePresenceAssuranceUiOptions(
      {this.autoStartDisabled,
      this.notReadyTintColor,
      this.readyTintColor,
      this.progressBarColor,
      this.readyFloatingPromptBackgroundColor,
      this.notReadyFloatingPromptBackgroundColor,
      this.readyOverlayStrokeColor,
      this.notReadyOverlayStrokeColor});

  Map<String, dynamic> toJson() => {
        'auto_start_disabled': autoStartDisabled,
        'not_ready_tint_color': notReadyTintColor?.hex,
        'ready_tint_color': readyTintColor?.hex,
        'progress_bar_color': progressBarColor?.hex,
        'ready_floating_prompt_background_color': readyFloatingPromptBackgroundColor?.hex,
        'not_ready_floating_prompt_background_color': notReadyFloatingPromptBackgroundColor?.hex,
        'ready_overlay_stroke_color': readyOverlayStrokeColor?.hex,
        'not_ready_overlay_stroke_color': notReadyOverlayStrokeColor?.hex,
      }._withoutNullValues();
}

/// Options relating to the appearance of the iProov user interface for LA claims.
class LivenessAssuranceUiOptions {
  /// The [Color] to use for the overlay tint when the scan is in progress.
  final Color? primaryTintColor;

  /// The [Color] to use for the overlay tint when when the scan is completed.
  final Color? secondaryTintColor;

  /// The [Color] to use for the background of the floating prompt (when enabled).
  final Color? floatingPromptBackgroundColor;

  /// The [Color] to use for the oval and reticle stroke lines.
  final Color? overlayStrokeColor;

  const LivenessAssuranceUiOptions({
    this.primaryTintColor,
    this.secondaryTintColor,
    this.floatingPromptBackgroundColor,
    this.overlayStrokeColor,
  });

  Map<String, dynamic> toJson() => {
        'primary_tint_color': primaryTintColor?.hex,
        'secondary_tint_color': secondaryTintColor?.hex,
        'floating_prompt_background_color': floatingPromptBackgroundColor?.hex,
        'overlay_stroke_color': overlayStrokeColor?.hex,
      }._withoutNullValues();
}

/// Options relating to the network configuration of the iProov SDK.
class NetworkOptions {
  /// A [List] of certificates to use for certificate pinning, as DER-encoded X.509 certificates as [Uint8List]s.
  ///
  /// Certificate pinning can be disabled by passing an empty array (never do this in production apps!)
  final List<Uint8List>? certificates;

  /// The network timeout for establishing a network connection.
  final Duration? timeout;
  final String? path;

  const NetworkOptions({
    this.certificates,
    this.timeout,
    this.path,
  });

  Map<String, dynamic> toJson() => {
        'certificates': certificates?.map((e) => base64.encode(e)).toList(),
        'timeout': timeout?.inSeconds,
        'path': path
      }._withoutNullValues();
}

/// Options relating to the capture experience.
class CaptureOptions {
  /// Capture options relating specifically to Genuine Presence Assurance (GPA).
  final GenuinePresenceAssuranceCaptureOptions? genuinePresenceAssurance;

  /// The [Camera] to be used for the iProov scan.
  ///
  /// This option only applies to Android.
  final Camera? camera;

  /// The [FaceDetector] to be used locally for face detection.
  ///
  /// This option only applies to Android.
  final FaceDetector? faceDetector;

  const CaptureOptions({
    this.genuinePresenceAssurance,
    this.camera,
    this.faceDetector,
  });

  Map<String, dynamic> toJson() => {
        'genuine_presence_assurance': genuinePresenceAssurance?.toJson(),
        'camera': camera?.stringValue,
        'face_detector': faceDetector?.stringValue
      }._withoutNullValues();
}

/// Options relating to the capture experience for Genuine Presence Assurance (GPA) claims.
class GenuinePresenceAssuranceCaptureOptions {
  /// The maximum deviation in pitch (in normalized units) to be applied for pose control.
  /// Requires a compatible [FaceDetector] to be specified.
  ///
  /// This option is not intended for general use. Contact iProov if you wish to use this feature.
  final double? maxPitch;

  /// The maximum deviation in yaw (in normalized units) to be applied for pose control.
  /// Requires a compatible [FaceDetector] to be specified.
  ///
  /// This option is not intended for general use. Contact iProov if you wish to use this feature.
  final double? maxYaw;

  /// The maximum deviation in roll (in normalized units) to be applies for pose control.
  /// Requires a compatible [FaceDetector] to be specified.
  ///
  /// This option is not intended for general use. Contact iProov if you wish to use this feature.
  final double? maxRoll;

  const GenuinePresenceAssuranceCaptureOptions({
    this.maxPitch,
    this.maxYaw,
    this.maxRoll,
  });

  Map<String, dynamic> toJson() => {
        'max_pitch': maxPitch,
        'max_yaw': maxYaw,
        'max_roll': maxRoll,
      }._withoutNullValues();
}

extension on Color {
  String get hex => '#' + value.toRadixString(16);
}

extension on Map<String, dynamic> {
  Map<String, dynamic> _withoutNullValues() => Map.fromEntries(entries.where((e) => e.value != null));
}
