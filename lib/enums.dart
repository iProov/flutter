enum Camera {
  front,
  external
}

extension CameraToString on Camera {
  String get stringValue => _enumCaseToString(toString());
}

enum FaceDetector {
  auto,
  classic,
  mlKit,
  blazeface
}

extension FaceDetectorToString on FaceDetector {
  String get stringValue => _enumCaseToString(toString());
}

enum Filter {
  classic,
  shaded,
  vibrant
}

extension FilterToString on Filter {
  String get stringValue => _enumCaseToString(toString());
}

enum Orientation {
  portrait,
  landscape,
  reversePortrait,
  reverseLandscape
}

extension OrientationToString on Orientation {
  String get stringValue => _enumCaseToString(toString());
}

String _enumCaseToString(String enumCase) {
  String text = enumCase.split('.').last;
  RegExp exp = RegExp(r'(?<=[a-z])[A-Z]'); // camelCase to underscore_separated
  return text.replaceAllMapped(exp, (Match m) => ('_' + m.group(0)!)).toLowerCase();
}
