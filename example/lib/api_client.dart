import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class IProovApiClient {
  final String _baseUrl = 'https://eu.rp.secure.iproov.me/api/v2/';
  final String _apiKey = '342a9ecc7a38610ab08620110c6250812d2a6c1d';//'<your api key here>';
  final String _secret = 'cefd2abf7aa3be084e1e8892fbdd262eb1553d03';//'<your secret here>';

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

enum ClaimType { ENROL, VERIFY, ID_MATCH }

extension ClaimTypeToString on ClaimType {
  String value() {
    switch (this) {
      case ClaimType.ENROL:
        return 'enrol';
      case ClaimType.VERIFY:
        return 'verify';
      default:
        return 'id_match';
    }
  }
}

enum AssuranceType { GENUINE_PRESENCE_ASSURANCE, LIVENESS }

extension AssuranceTypeToString on AssuranceType {
  String value() {
    if (this == AssuranceType.GENUINE_PRESENCE_ASSURANCE)
      return 'genuine_presence';
    else
      return 'liveness';
  }
}
