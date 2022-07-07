import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart';

import 'validation_result.dart';

/// THIS CODE IS PROVIDED FOR DEMO PURPOSES ONLY AND SHOULD NOT BE USED IN
/// PRODUCTION! YOU SHOULD NEVER EMBED YOUR CREDENTIALS IN A PUBLIC APP RELEASE!
///   THESE API CALLS SHOULD ONLY EVER BE MADE FROM YOUR BACK-END SERVER

class UserNotRegisteredException implements Exception {}

class NotFoundException implements Exception {}

class ApiClient {
  final String baseUrl;
  final String apiKey;
  final String secret;

  const ApiClient({required this.baseUrl, required this.apiKey, required this.secret});

  String get _normalizedBaseUrl {
    String normalizedBaseUrl = baseUrl;

    if (normalizedBaseUrl.endsWith('/')) {
      normalizedBaseUrl = normalizedBaseUrl.substring(0, normalizedBaseUrl.length - 1);
    }

    if (!normalizedBaseUrl.endsWith('/api/v2')) {
      normalizedBaseUrl += '/api/v2';
    }

    return normalizedBaseUrl;
  }

  Future<String> getToken(AssuranceType assuranceType, ClaimType claimType, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_normalizedBaseUrl/claim/${claimType.stringValue}/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'api_key': apiKey,
          'secret': secret,
          'resource': 'com.iproov.dart_api_client',
          'client': 'dart',
          'user_id': userId,
          'assurance_type': assuranceType.stringValue
        }),
      );

      _ensureSuccess(response);

      final json = jsonDecode(response.body);
      return json['token'];
    } on SocketException {
      throw Exception('No internet connection');
    }
  }

  Future<String> enrolPhoto(String token, Image image, PhotoSource source) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_normalizedBaseUrl/claim/enrol/image'))
        ..fields['api_key'] = apiKey
        ..fields['secret'] = secret
        ..fields['rotation'] = '0'
        ..fields['token'] = token
        ..fields['source'] = source.stringValue
        ..files.add(http.MultipartFile.fromBytes('image', encodeJpg(image),
            filename: 'image.jpg', contentType: MediaType.parse('image/jpeg')));

      final response = await request.send();
      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        throw Exception('Error ${response.statusCode}: $body');
      }

      final bytes = await response.stream.toBytes();
      final json = jsonDecode(utf8.decode(bytes));

      return json['token'];
    } on SocketException {
      throw Exception('No internet connection');
    }
  }

  Future<String> enrolPhotoAndGetVerifyToken(String userId, Image image, PhotoSource source) async {
    final enrolToken = await getToken(AssuranceType.genuinePresenceAssurance, ClaimType.enrol, userId);
    await enrolPhoto(enrolToken, image, source);
    return await getToken(AssuranceType.genuinePresenceAssurance, ClaimType.verify, userId);
  }

  Future<ValidationResult> validate(String token, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_normalizedBaseUrl/claim/verify/validate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'api_key': apiKey, 'secret': secret, 'user_id': userId, 'token': token, 'client': 'dart'}),
      );

      _ensureSuccess(response);

      final json = jsonDecode(response.body);

      return ValidationResult.fromJson(json);
    } on SocketException {
      throw Exception('No internet connection');
    }
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode == 200) return;
    if (response.statusCode == 404) throw NotFoundException();

    final json = jsonDecode(response.body);
    if (json['error'] == 'no_user') {
      throw UserNotRegisteredException();
    } else if (json['error_description'] != null) {
      throw Exception(json['error_description']);
    } else {
      throw Exception('Unknown error');
    }
  }
}

enum PhotoSource { electronicID, opticalID }

extension on PhotoSource {
  String get stringValue => (this == PhotoSource.electronicID) ? 'eid' : 'oid';
}

enum ClaimType { enrol, verify }

extension on ClaimType {
  String get stringValue => toString().split('.').last;
}

enum AssuranceType { genuinePresenceAssurance, livenessAssurance }

extension on AssuranceType {
  String get stringValue => (this == AssuranceType.genuinePresenceAssurance) ? 'genuine_presence' : 'liveness';
}
