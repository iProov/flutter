import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class TokenApi {
  final String _baseUrl = 'https://eu.rp.secure.iproov.me/api/v2/';
  final String _apiKey = '<your api key here>';
  final String _secret = '<your secret here>';

  Future<String> getToken(String userID, String claimType, String assuranceType) async {
    try {
      print('token requested');
      final response = await http.post(
          _baseUrl + 'claim/' + claimType + '/token',
          headers: { 'Content-Type': 'application/json' },
          body: jsonEncode(<String, String>{
            'api_key': _apiKey,
            'secret': _secret,
            'resource': 'com.iproov.iproov_sdk.flutter',
            'client': "android",
            'user_id': userID,
            'assurance_type': "genuine_presence"
          }),
        );
      if (response.statusCode == 200) {
        var token = jsonDecode(response.body)['token'];
        print('token received $token}');
        return token;
      } else {
        throw Exception('Failed to load token ${response.statusCode} ${response.body}');
      }
    } on SocketException {
      print('Network failure');
      throw Exception('No internet connection');
    }
  }

  String get baseUrl => _baseUrl;
}