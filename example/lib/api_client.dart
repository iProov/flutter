import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart';

/// THIS CODE IS PROVIDED FOR DEMO PURPOSES ONLY AND SHOULD NOT BE USED IN
/// PRODUCTION! YOU SHOULD NEVER EMBED YOUR CREDENTIALS IN A PUBLIC APP RELEASE!
///   THESE API CALLS SHOULD ONLY EVER BE MADE FROM YOUR BACK-END SERVER

class ApiClient {
  final String baseUrl;
  final String apiKey;
  final String secret;

  ApiClient(this.baseUrl, this.apiKey, this.secret);

  Future<String> getToken(AssuranceType assuranceType, ClaimType claimType, String userId) async {
    try {
      final response = await http.post('${baseUrl}claim/${claimType.stringValue}/token',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'api_key': apiKey,
          'secret': secret,
          'resource': 'com.iproov.flutter',
          'client': 'android',
          'user_id': userId,
          'assurance_type': assuranceType.stringValue
        }),
      );

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        return json['token'];
      } else throw Exception('Error ${response.statusCode}: ${response.body}');

    } on SocketException {
      throw Exception('No internet connection');
    }
  }

  Future<String> enrolPhoto(String token, Image image, PhotoSource source) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('${baseUrl}claim/enrol/image'))
        ..fields['api_key'] = apiKey
        ..fields['secret'] = secret
        ..fields['rotation'] = "0"
        ..fields['token'] = token
        ..fields['source'] = source.stringValue
        ..files.add(http.MultipartFile.fromBytes(
            'image',
            encodeJpg(image),
            filename:
            'image.jpg',
            contentType: MediaType.parse('image/jpeg')
        ));

      var response = await request.send();
      if (response.statusCode != 200) {
        throw Exception('Error ${response.statusCode}');
      }

      var bytes = await response.stream.toBytes();
      var json = jsonDecode(utf8.decode(bytes));

      return json['token'];
    } on SocketException {
      throw Exception('No internet connection');
    }
  }

  Future<String> enrolPhotoAndGetVerifyToken(String userId, Image image, PhotoSource source) async {
    var enrolToken = await getToken(AssuranceType.genuinePresenceAssurance, ClaimType.enrol, userId);
    await enrolPhoto(enrolToken, image, source);
    return await getToken(AssuranceType.genuinePresenceAssurance, ClaimType.verify, userId);
  }
}

enum PhotoSource {
  electronicID,
  opticalID
}

extension PhotoSourceToString on PhotoSource {
  String get stringValue {
    if (this == PhotoSource.electronicID) {
      return "eid";
    } else {
      return "oid";
    }
  }
}

enum ClaimType {
  enrol,
  verify
}

extension ClaimTypeToString on ClaimType {
  String get stringValue => toString().split('.').last;
}

enum AssuranceType {
  genuinePresenceAssurance,
  livenessAssurance
}

extension AssuranceTypeToString on AssuranceType {
  String get stringValue {
    if (this == AssuranceType.genuinePresenceAssurance)
      return 'genuine_presence';
    else {
      return 'liveness';
    }
  }
}
