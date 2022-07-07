import 'dart:convert';

import 'package:image/image.dart';

class ValidationResult {
  final bool isPassed;
  final String token;
  final Image? image;
  final String? failureReason;

  const ValidationResult({
    required this.isPassed,
    required this.token,
    required this.image,
    required this.failureReason,
  });

  factory ValidationResult.fromJson(Map<String, dynamic> json) => ValidationResult(
      isPassed: json['passed'],
      token: json['token'],
      image: _imageFromBase64(json['frame']),
      failureReason: json['result']?['reason']);

  static Image? _imageFromBase64(String? value) => (value == null) ? null : decodeImage(base64Decode(value));
}
