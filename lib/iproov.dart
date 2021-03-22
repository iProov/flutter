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

  static final events = _iProovListenerEventChannel
      .receiveBroadcastStream()
      .map((result) => IProovEvent.fromMap(result));

  static Future<dynamic> launch(String streamingUrl, String token,
      [Options options]) {
    return _iProovMethodChannel
        .invokeMethod('launch', <String, dynamic>{
          'streamingURL': streamingUrl,
          'token': token,
          'optionsJSON': json.encode(options)
        });
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
  Filter filter = Filter.shaded;
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
  Orientation orientation = Orientation.portrait;
  bool useLegacyConnectingUi = false;
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
        'use_legacy_connecting_ui': useLegacyConnectingUi,
        'activitycompatibility_request_code': activityCompatibilityRequestCode
      });

  static String orientationToJson(Orientation orientation) {
    switch (orientation) {
      case Orientation.portrait:
        return "portrait";
      case Orientation.landscape:
        return "landscape";
      case Orientation.reversePortrait:
        return "reverse_portrait";
      case Orientation.reverseLandscape:
        return "reverse_landscape";
    }
  }

  static String filterToString(Filter filter) {
    switch (filter) {
      case Filter.classic:
        return "classic";
      case Filter.shaded:
        return "shaded";
      case Filter.vibrant:
        return "vibrant";
    }
  }

  static String colorToString(Color color) {
    return "#" + color.value.toRadixString(16);
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
  Camera camera = Camera.front;
  FaceDetector faceDetector = FaceDetector.auto;

  Map<String, dynamic> toJson() => removeNulls({
        'max_pitch': maxPitch,
        'max_yaw': maxYaw,
        'max_roll': maxRoll,
        'camera': cameraToString(camera),
        'face_detector': faceDetectorToString(faceDetector)
      });

  static String cameraToString(Camera camera) {
    switch (camera) {
      case Camera.front:
        return "front";
      case Camera.external:
        return "external";
    }
  }

  static String faceDetectorToString(FaceDetector faceDetector) {
    switch (faceDetector) {
      case FaceDetector.auto:
        return "auto";
      case FaceDetector.classic:
        return "classic";
      case FaceDetector.blazeFace:
        return "blazeface";
      case FaceDetector.mlKit:
        return "mlkit";
    }
  }
}

enum Camera { front, external }
enum FaceDetector { auto, classic, mlKit, blazeFace }
enum Filter { classic, shaded, vibrant }
enum Orientation { portrait, landscape, reversePortrait, reverseLandscape }

Map<String, dynamic> removeNulls(Map<String, dynamic> map) {
  map.removeWhere((key, value) => key == null || value == null);
  return map;
}
