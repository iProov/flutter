import 'dart:convert';

import 'package:image/image.dart';

class ValidationResult {
  final bool isPassed;
  final String token;
  final Image? image;
  final Image? jpegImage;
  final String? failureReason;
  final Map<String, dynamic>? signals;

  const ValidationResult({
    required this.isPassed,
    required this.token,
    required this.image,
    required this.jpegImage,
    required this.failureReason,
    required this.signals,
  });

  factory ValidationResult.fromJson(Map<String, dynamic> json) => ValidationResult(
        isPassed: json['passed'],
        token: json['token'],
        image: _imageFromBase64(json['frame']),
        jpegImage: _imageFromBase64(json['frame_jpeg']),
        failureReason: json['result']?['reason'],
        signals: json['signals'],
      );

  static Image? _imageFromBase64(String? value) => (value == null) ? null : decodeImage(base64Decode(value));
}
