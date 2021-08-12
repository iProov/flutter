import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

/// THIS CODE IS PROVIDED FOR DEMO PURPOSES ONLY AND SHOULD NOT BE USED IN
/// PRODUCTION! YOU SHOULD NEVER EMBED YOUR CREDENTIALS IN A PUBLIC APP RELEASE!
///   THESE API CALLS SHOULD ONLY EVER BE MADE FROM YOUR BACK-END SERVER

class ApiClient {
  final String baseUrl;
  final String apiKey;
  final String secret;

  ApiClient(this.baseUrl, this.apiKey, this.secret);

  Future<String> getToken(
      String userId, ClaimType claimType, AssuranceType assuranceType) async {
    try {
      final response = await http.post(
        baseUrl + 'claim/' + claimType.value() + '/token',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(<String, String>{
          'api_key': apiKey,
          'secret': secret,
          'resource': 'com.iproov.flutter',
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
            'Error ${response.statusCode}: ${response.body}');
      }
    } on SocketException {
      throw Exception('No internet connection');
    }
  }
}

enum ClaimType {
  enrol,
  verify
}

extension ClaimTypeToString on ClaimType {
  String value() {
    return this.toString().split('.').last;
  }
}

enum AssuranceType {
  genuinePresenceAssurance,
  livenessAssurance
}

extension AssuranceTypeToString on AssuranceType {
  String value() {
    if (this == AssuranceType.genuinePresenceAssurance)
      return 'genuine_presence';
    else
      return 'liveness';
  }
}
