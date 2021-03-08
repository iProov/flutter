import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

abstract class IProovEvent {
  static const connecting = const IProovEventConnecting();
  static const connected = const IProovEventConnected();
  static const cancelled = const IProovEventCancelled();

  factory IProovEvent.progress(double progress, String message) =
      IProovEventProgress;

  factory IProovEvent.success(String token) = IProovEventSuccess;

  factory IProovEvent.failure(
      String token, String reason, String feedbackCode) = IProovEventFailure;

  factory IProovEvent.error(String reason, String message, String exception) =
      IProovEventError;

  factory IProovEvent.fromMap(Map map) {
    switch (map['event']) {
      case 'connecting':
        return connecting;
      case 'connected':
        return connected;
      case 'processing':
        return IProovEvent.progress(map['progress'], map['message']);
      case 'success':
        return IProovEvent.success(map['token']);
      case 'failure':
        return IProovEvent.failure(
            map['token'], map['reason'], map['feedbackCode']);
      case 'cancelled':
        return cancelled;
      case 'error':
        return IProovEvent.error(map['reason'], map['message'], map['exception']);
    }
    return null;
  }
}

class IProovEventConnecting implements IProovEvent {
  const IProovEventConnecting();
}

class IProovEventConnected implements IProovEvent {
  const IProovEventConnected();
}

class IProovEventCancelled implements IProovEvent {
  const IProovEventCancelled();
}

class IProovEventProgress implements IProovEvent {
  final double progress;
  final String message;

  const IProovEventProgress(this.progress, this.message);
}

class IProovEventSuccess implements IProovEvent {
  final String token;

  const IProovEventSuccess(this.token);
}

class IProovEventFailure implements IProovEvent {
  final String token;
  final String reason;
  final String feedbackCode;

  const IProovEventFailure(this.token, this.reason, this.feedbackCode);
}

class IProovEventError implements IProovEvent {
  final String reason;
  final String message;
  final String exception;

  const IProovEventError(this.reason, this.message, this.exception);
}

class IProov {
  static const MethodChannel _iProovMethodChannel =
      const MethodChannel('com.iproov.sdk');

  static const EventChannel _iProovListenerEventChannel =
      EventChannel('com.iproov.sdk.listener');

  static Stream<IProovEvent> launch(String streamingUrl, String token,
      [Options options]) {
    final resultStream = _iProovMethodChannel
        .invokeMethod('launch', <String, dynamic>{
          'streamingURL': streamingUrl,
          'token': token,
          'optionsJSON': json.encode(options)
        })
        .asStream()
        .asyncExpand((_) => _iProovListenerEventChannel
            .receiveBroadcastStream()
            .map((result) => IProovEvent.fromMap(result)));
    return resultStream;
  }

  // Private constructor
  IProov._();
}

class Options {
  UI ui = new UI();
  Network network = new Network();
  Capture capture = new Capture();

  Map<String, dynamic> toJson() => {
        'ui': ui.toJson(),
        'network': network.toJson(),
        'capture': capture.toJson()
      };
}

class UI {
  bool autoStartDisabled = false;
  Filter filter = Filter.SHADED;
  Color lineColor = Color(0xFF404040);
  Color backgroundColor = Color(0xFFFAFAFA);
  Color loadingTintColor = Color(0xFF5c5c5c);
  Color notReadyTintColor = Color(0xFFf5a623);
  Color readyTintColor = Color(0xFF01bf46);
  Color livenessTintColor = Color(0xFF1756E5);
  String title;
  String fontPath;
  String fontResource;
  String logoImageResource;

  // Drawable logoImageDrawable = null;
  bool scanLineDisabled = false;
  bool enableScreenshots = false;
  Orientation orientation = Orientation.PORTRAIT;
  bool useLegacyConnectingUI = false;
  int activityCompatibilityRequestCode = -1;

  Map<String, dynamic> toJson() => removeNulls({
        'auto_start_disabled': autoStartDisabled,
        'filter': filterToString(filter),
        'line_color': colorToString(lineColor),
        'background_color': colorToString(backgroundColor),
        'loading_tint_color': colorToString(loadingTintColor),
        'not_ready_tint_color': colorToString(notReadyTintColor),
        'ready_tint_color': colorToString(readyTintColor),
        'liveness_tint_color': colorToString(livenessTintColor),
        'title': title,
        'font_path': fontPath,
        'font_resource': fontResource,
        'logo_image_resource': logoImageResource,
        'scan_line_disabled': scanLineDisabled,
        'enable_screenshots': enableScreenshots,
        'orientation': orientationToJson(orientation),
        'use_legacy_connecting_ui': useLegacyConnectingUI,
        'activitycompatibility_request_code': activityCompatibilityRequestCode
      });

  static String orientationToJson(Orientation orientation) {
    switch (orientation) {
      case Orientation.PORTRAIT:
        return "portrait";
      case Orientation.LANDSCAPE:
        return "landscape";
      case Orientation.REVERSE_PORTRAIT:
        return "reverse_portrait";
      case Orientation.REVERSE_LANDSCAPE:
        return "reverse_landscape";
    }
  }

  static String filterToString(Filter filter) {
    switch (filter) {
      case Filter.CLASSIC:
        return "classic";
      case Filter.SHADED:
        return "shaded";
      case Filter.VIBRANT:
        return "vibrant";
    }
  }

  static String colorToString(Color color) {
    return "#" + color.value.toRadixString(16).substring(2);
  }
}

class Network {
  bool disableCertificatePinning = false;
  List<String> certificates;
  int timeoutSecs = 10;
  String path = "/socket.io/v2/";

  Map<String, dynamic> toJson() => removeNulls({
        'disable_certificate_pinning': disableCertificatePinning,
        'certificates': certificates,
        'timeout': timeoutSecs,
        'path': path
      });
}

class Capture {
  double maxPitch;
  double maxYaw;
  double maxRoll;
  Camera camera = Camera.FRONT;
  FaceDetector faceDetector = FaceDetector.AUTO;

  Map<String, dynamic> toJson() => removeNulls({
        'max_pitch': maxPitch,
        'max_yaw': maxYaw,
        'max_roll': maxRoll,
        'camera': cameraToString(camera),
        'face_detector': faceDetectorToString(faceDetector)
      });

  static String cameraToString(Camera camera) {
    switch (camera) {
      case Camera.FRONT:
        return "front";
      case Camera.EXTERNAL:
        return "external";
    }
  }

  static String faceDetectorToString(FaceDetector faceDetector) {
    switch (faceDetector) {
      case FaceDetector.AUTO:
        return "auto";
      case FaceDetector.CLASSIC:
        return "classic";
      case FaceDetector.BLAZEFACE:
        return "blazeface";
      case FaceDetector.ML_KIT:
        return "mlkit";
    }
  }
}

enum Camera { FRONT, EXTERNAL }
enum FaceDetector { AUTO, CLASSIC, ML_KIT, BLAZEFACE }
enum Filter { CLASSIC, SHADED, VIBRANT }
enum Orientation { PORTRAIT, LANDSCAPE, REVERSE_PORTRAIT, REVERSE_LANDSCAPE }

Map<String, dynamic> removeNulls(Map<String, dynamic> map) {
  map.removeWhere((key, value) => key == null || value == null);
  return map;
}
