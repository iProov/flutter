import 'dart:convert';
import 'dart:ui';

import 'package:image/image.dart' hide Color;
import 'package:iproov_flutter/enums.dart';

// TODO: For all the classes in this file, identify which properties need to be null
// and which ones don't. Non-nullable should be the default.
// Note: non-nullable variables need to be required or have a default value in the constructor.

class Options {
  const Options({
    this.ui = const UiOptions(),
    this.network = const NetworkOptions(),
    this.capture = const CaptureOptions(),
  });
  final UiOptions ui;
  final NetworkOptions network;
  final CaptureOptions capture;

  Map<String, dynamic> toJson() => {
        'ui': ui.toJson(),
        'network': network.toJson(),
        'capture': capture.toJson()
      };
}

class UiOptions {
  const UiOptions({
    this.genuinePresenceAssurance = const GenuinePresenceAssuranceUiOptions(),
    this.livenessAssurance = const LivenessAssuranceUiOptions(),
    this.filter,
    this.lineColor,
    this.backgroundColor,
    this.title,
    this.fontPath,
    this.fontResource,
    this.font,
    this.logoImage,
    this.closeButtonImage,
    this.closeButtonTintColor,
    this.enableScreenshots,
    this.orientation,
    this.activityCompatibilityRequestCode,
  });
  final GenuinePresenceAssuranceUiOptions genuinePresenceAssurance;
  final LivenessAssuranceUiOptions livenessAssurance;
  final Filter? filter;
  final Color? lineColor;
  final Color? backgroundColor;
  final String? title;
  final String? fontPath; // TODO: Not cross-platform
  final String? fontResource; // TODO: Not cross-platform
  final String? font; // TODO: Not cross-platform
  final Image? logoImage;
  final Image? closeButtonImage; // TODO: Not yet supported in iOS SDK
  final Color? closeButtonTintColor;

  // final Drawable logoImageDrawable = null;
  final bool? enableScreenshots;
  final Orientation? orientation;
  final int? activityCompatibilityRequestCode;

  Map<String, dynamic> toJson() {
    return removeNulls({
      'genuine_presence_assurance': genuinePresenceAssurance.toJson(),
      'liveness_assurance': livenessAssurance.toJson(),
      'filter': filter?.stringValue,
      'line_color': lineColor?.hex,
      'background_color': backgroundColor?.hex,
      'title': title,
      'font_path': fontPath,
      'font_resource': fontResource,
      'font': font,
      'enable_screenshots': enableScreenshots,
      'orientation': orientation?.stringValue,
      'activity_compatibility_request_code': activityCompatibilityRequestCode,
      'close_button_tint_color': closeButtonTintColor?.hex,
      if (logoImage != null) 'logo_image': base64.encode(encodePng(logoImage!)),
      if (closeButtonImage != null)
        'close_button_image': base64.encode(encodePng(closeButtonImage!)),
    });
  }
}

class GenuinePresenceAssuranceUiOptions {
  const GenuinePresenceAssuranceUiOptions({
    this.autoStartDisabled,
    this.notReadyTintColor,
    this.readyTintColor,
    this.progressBarColor,
  });
  final bool? autoStartDisabled;
  final Color? notReadyTintColor;
  final Color? readyTintColor;
  final Color? progressBarColor;

  Map<String, dynamic> toJson() => removeNulls({
        'auto_start_disabled': autoStartDisabled,
        'not_ready_tint_color': notReadyTintColor?.hex,
        'ready_tint_color': readyTintColor?.hex,
        'progress_bar_color': progressBarColor?.hex
      });
}

class LivenessAssuranceUiOptions {
  const LivenessAssuranceUiOptions(
      {this.primaryTintColor, this.secondaryTintColor});
  final Color? primaryTintColor;
  final Color? secondaryTintColor;

  Map<String, dynamic> toJson() => removeNulls({
        'primary_tint_color': primaryTintColor?.hex,
        'secondary_tint_color': secondaryTintColor?.hex,
      });
}

class NetworkOptions {
  const NetworkOptions({
    this.certificates,
    this.timeout,
    this.path,
  });
  final List<String>? certificates; // TODO: Not cross-platform
  final Duration? timeout;
  final String? path;

  Map<String, dynamic> toJson() => removeNulls({
        'certificates': certificates,
        'timeout': timeout?.inSeconds,
        'path': path
      });
}

class CaptureOptions {
  const CaptureOptions({
    this.genuinePresenceAssurance =
        const GenuinePresenceAssuranceCaptureOptions(),
    this.camera,
    this.faceDetector,
  });
  final GenuinePresenceAssuranceCaptureOptions genuinePresenceAssurance;
  final Camera? camera;
  final FaceDetector? faceDetector;

  Map<String, dynamic> toJson() => removeNulls({
        'genuine_presence_assurance': genuinePresenceAssurance.toJson(),
        'camera': camera?.stringValue,
        'face_detector': faceDetector?.stringValue
      });
}

class GenuinePresenceAssuranceCaptureOptions {
  const GenuinePresenceAssuranceCaptureOptions({
    this.maxPitch,
    this.maxYaw,
    this.maxRoll,
  });
  final double? maxPitch;
  final double? maxYaw;
  final double? maxRoll;

  Map<String, dynamic> toJson() => removeNulls({
        'max_pitch': maxPitch,
        'max_yaw': maxYaw,
        'max_roll': maxRoll,
      });
}

extension ColorToHex on Color {
  String get hex => "#" + value.toRadixString(16);
}

Map<String, dynamic> removeNulls(Map<String, dynamic> map) {
  map.removeWhere((key, value) => value == null);
  return map;
}
