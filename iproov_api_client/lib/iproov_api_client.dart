import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart';

import 'validation_result.dart';

/// THIS CODE IS PROVIDED FOR DEMO PURPOSES ONLY AND SHOULD NOT BE USED IN
/// PRODUCTION! YOU SHOULD NEVER EMBED YOUR CREDENTIALS IN A PUBLIC APP RELEASE!
///   THESE API CALLS SHOULD ONLY EVER BE MADE FROM YOUR BACK-END SERVER

class ApiException implements Exception {
  final String? code;
  final String? message;

  const ApiException({this.code, this.message});

  String toString() {
    return message ?? 'Unknown error';
  }

  factory ApiException._fromJson(Map<String, dynamic> json) {
    String errorCode = json['error'];
    String errorMessage = json['error_description'];

    if (errorCode == 'no_user') {
      return UserNotRegisteredException(code: errorCode, message: errorMessage);
    } else if (errorCode == 'invalid_user_id') {
      return InvalidUserIdException(code: errorCode, message: errorMessage);
    } else if (errorCode == 'invalid_assurance_type') {
      return InvalidAssuranceTypeException(code: errorCode, message: errorMessage);
    } else if (errorCode == 'already_enrolled') {
      return AlreadyEnrolledException(code: errorCode, message: errorMessage);
    } else if (errorCode == 'invalid_key') {
      return InvalidCredentialsException(code: errorCode, message: errorMessage);
    } else if (errorCode == 'invalid_token') {
      return InvalidTokenException(code: errorCode, message: errorMessage);
    } else {
      return ApiException(code: errorCode, message: errorMessage);
    }
  }
}

class UserNotRegisteredException extends ApiException {
  const UserNotRegisteredException({super.code, super.message});
}

class InvalidUserIdException extends ApiException {
  const InvalidUserIdException({super.code, super.message});
}

class InvalidAssuranceTypeException extends ApiException {
  const InvalidAssuranceTypeException({super.code, super.message});
}

class AlreadyEnrolledException extends ApiException {
  const AlreadyEnrolledException({super.code, super.message});
}

class InvalidCredentialsException extends ApiException {
  const InvalidCredentialsException({super.code, super.message});
}

class InvalidTokenException extends ApiException {
  const InvalidTokenException({super.code, super.message});
}

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

  Future<String> getToken({
    required AssuranceType assuranceType,
    required ClaimType claimType,
    required String userId,
    Map<String, dynamic> additionalOptions = const {},
  }) async {
    final response = await http.post(
      Uri.parse('$_normalizedBaseUrl/claim/${claimType.stringValue}/token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'api_key': apiKey,
        'secret': secret,
        'resource': 'com.iproov.dart_api_client',
        'client': 'dart',
        'user_id': userId,
        'assurance_type': assuranceType.stringValue,
        ...additionalOptions,
      }),
    );

    _ensureSuccess(response);

    final json = jsonDecode(response.body);
    return json['token'];
  }

  Future<String> enrolPhoto({
    required String token,
    required Image image,
    required PhotoSource source,
    Map<String, String> additionalOptions = const {},
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$_normalizedBaseUrl/claim/enrol/image'))
      ..fields['api_key'] = apiKey
      ..fields['secret'] = secret
      ..fields['rotation'] = '0'
      ..fields['token'] = token
      ..fields['source'] = source.stringValue
      ..fields.addAll(additionalOptions)
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
  }

  Future<String> enrolPhotoAndGetVerifyToken({
    AssuranceType assuranceType = AssuranceType.genuinePresenceAssurance,
    required String userId,
    required Image image,
    required PhotoSource source,
    Map<String, dynamic> additionalOptions = const {},
  }) async {
    final enrolToken = await getToken(
      assuranceType: AssuranceType.genuinePresenceAssurance,
      claimType: ClaimType.enrol,
      userId: userId,
      additionalOptions: additionalOptions,
    );
    await enrolPhoto(
      token: enrolToken,
      image: image,
      source: source,
    );
    return await getToken(
      assuranceType: assuranceType,
      claimType: ClaimType.verify,
      userId: userId,
    );
  }

  Future<ValidationResult> validate({
    required String token,
    required String userId,
    Map<String, dynamic> additionalOptions = const {},
  }) async {
    final response = await http.post(
      Uri.parse('$_normalizedBaseUrl/claim/verify/validate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'api_key': apiKey,
        'secret': secret,
        'user_id': userId,
        'token': token,
        'client': 'dart',
        ...additionalOptions,
      }),
    );

    _ensureSuccess(response);

    final json = jsonDecode(response.body);

    return ValidationResult.fromJson(json);
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    if (response.statusCode == 404) throw NotFoundException();

    final json = jsonDecode(response.body);

    throw ApiException._fromJson(json);
  }
}

enum PhotoSource {
  electronicID('eid'),
  opticalID('oid');

  const PhotoSource(this.stringValue);

  final String stringValue;
}

enum ClaimType {
  enrol,
  verify;

  String get stringValue => toString().split('.').last;
}

enum AssuranceType {
  genuinePresenceAssurance('genuine_presence'),
  livenessAssurance('liveness');

  const AssuranceType(this.stringValue);

  final String stringValue;
}
