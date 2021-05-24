import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

/*
 * WARNING - this Api Client is ONLY intended for DEMONSTRATION and EVALUATION purposes.
 * We STRONGLY recommend that this code is NOT used in a production CLIENT.
 * The purpose of this code is to quickly enable the creation of a stand alone client before
 * investment is made in putting this functionality into a server, where it belongs
 * We also recommend NOT to put your apiKey and Secret into your GitHub repository.
 */
class IProovApiClient {
  final String _baseUrl = 'https://eu.rp.secure.iproov.me/api/v2/';
  final String _apiKey = 'API_KEY';
  final String _secret = 'API_SECRET';

  String get baseUrl => _baseUrl;

  Future<String> getToken(
      String userId, ClaimType claimType, AssuranceType assuranceType) async {
    try {
      final response = await http.post(
        _baseUrl + 'claim/' + claimType.value() + '/token',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(<String, String>{
          'api_key': _apiKey,
          'secret': _secret,
          'resource': 'com.iproov.iproov_sdk.flutter',
          'client': 'android',
          'user_id': userId,
          'assurance_type': assuranceType.value()
        }),
      );
      if (response.statusCode == 200) {
        var token = jsonDecode(response.body)['token'];
        return token;
      } else {
        throw Exception(
            'Failed to load token ${response.statusCode} ${response.body}');
      }
    } on SocketException {
      throw Exception('No internet connection');
    }
  }
}

enum ClaimType { enrol, verify }

extension ClaimTypeToString on ClaimType {
  String value() {
    switch (this) {
      case ClaimType.enrol:
        return 'enrol';
      case ClaimType.verify:
      default: // Stupid compiler!
        return 'verify';
    }
  }
}

enum AssuranceType { genuinePresenceAssurance, liveness }

extension AssuranceTypeToString on AssuranceType {
  String value() {
    if (this == AssuranceType.genuinePresenceAssurance)
      return 'genuine_presence';
    else
      return 'liveness';
  }
}
