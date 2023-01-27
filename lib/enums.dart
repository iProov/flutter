import 'package:flutter/foundation.dart';

enum Camera {
  front,
  external,
}

extension CameraToString on Camera {
  String get stringValue => _enumCaseToString(describeEnum(this));
}

enum FaceDetector {
  auto,
  classic,
  mlKit,
  blazeface,
}

extension FaceDetectorToString on FaceDetector {
  String get stringValue => _enumCaseToString(describeEnum(this));
}

enum Orientation {
  portrait,
  landscape,
  reversePortrait,
  reverseLandscape,
}

extension OrientationToString on Orientation {
  String get stringValue => _enumCaseToString(describeEnum(this));
}

String _enumCaseToString(String text) {
  final exp = RegExp(r'(?<=[a-z])[A-Z]'); // camelCase to underscore_separated
  return text.replaceAllMapped(exp, (Match m) => ('_' + m.group(0)!)).toLowerCase();
}

enum Canceller { user, app }
