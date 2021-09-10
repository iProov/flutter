import 'dart:convert';
import 'dart:ui';

import 'package:image/image.dart' hide Color;
import 'package:iproov_flutter/enums.dart';

class Options {
  UiOptions ui = UiOptions();
  NetworkOptions network = NetworkOptions();
  CaptureOptions capture = CaptureOptions();

  Map<String, dynamic> toJson() => {
        'ui': ui.toJson(),
        'network': network.toJson(),
        'capture': capture.toJson()
      };
}

class UiOptions {
  GenuinePresenceAssuranceUiOptions genuinePresenceAssurance =
      GenuinePresenceAssuranceUiOptions();
  LivenessAssuranceUiOptions livenessAssurance = LivenessAssuranceUiOptions();
  Filter? filter;
  Color? lineColor;
  Color? backgroundColor;
  String? title;
  String? fontPath; // TODO: Not cross-platform
  String? fontResource; // TODO: Not cross-platform
  String? font; // TODO: Not cross-platform
  Image? logoImage;
  Image? closeButtonImage; // TODO: Not yet supported in iOS SDK
  Color? closeButtonTintColor;

  // Drawable logoImageDrawable = null;
  bool? enableScreenshots;
  Orientation? orientation;
  int? activityCompatibilityRequestCode;

  Map<String, dynamic> toJson() {
    var map = removeNulls({
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
    });

    if (logoImage != null) {
      map['logo_image'] = base64.encode(encodePng(logoImage!));
    }

    if (closeButtonImage != null) {
      map['close_button_image'] = base64.encode(encodePng(closeButtonImage!));
    }

    return map;
  }
}

class GenuinePresenceAssuranceUiOptions {
  bool? autoStartDisabled;
  Color? notReadyTintColor;
  Color? readyTintColor;
  Color? progressBarColor;

  Map<String, dynamic> toJson() => removeNulls({
        'auto_start_disabled': autoStartDisabled,
        'not_ready_tint_color': notReadyTintColor?.hex,
        'ready_tint_color': readyTintColor?.hex,
        'progress_bar_color': progressBarColor?.hex
      });
}

class LivenessAssuranceUiOptions {
  Color? primaryTintColor;
  Color? secondaryTintColor;

  Map<String, dynamic> toJson() => removeNulls({
        'primary_tint_color': primaryTintColor?.hex,
        'secondary_tint_color': secondaryTintColor?.hex,
      });
}

class NetworkOptions {
  List<String>? certificates; // TODO: Not cross-platform
  Duration? timeout;
  String? path;

  Map<String, dynamic> toJson() => removeNulls({
        'certificates': certificates,
        'timeout': timeout?.inSeconds,
        'path': path
      });
}

class CaptureOptions {
  GenuinePresenceAssuranceCaptureOptions genuinePresenceAssurance =
      GenuinePresenceAssuranceCaptureOptions();
  Camera? camera;
  FaceDetector? faceDetector;

  Map<String, dynamic> toJson() => removeNulls({
        'genuine_presence_assurance': genuinePresenceAssurance.toJson(),
        'camera': camera?.stringValue,
        'face_detector': faceDetector?.stringValue
      });
}

class GenuinePresenceAssuranceCaptureOptions {
  double? maxPitch;
  double? maxYaw;
  double? maxRoll;

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
