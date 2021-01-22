
import 'package:flutter/services.dart';

class IProovSDK {
    static const MethodChannel _iProovMethodChannel =
        const MethodChannel('com.iproov.sdk');

    static const EventChannel iProovListenerEventChannel =
        EventChannel('com.iproov.sdk.listener');

    static void launch(String streamingUrl, String token) async {
        _iProovMethodChannel.invokeMethod('launch', <String, dynamic>{
            'streamingUrl': streamingUrl,
            'token': token
        });
    }

    static void launchWithOptions(String streamingUrl, String token, String optionsJson) async {
        _iProovMethodChannel.invokeMethod('launch', <String, dynamic>{
            'streamingUrl': streamingUrl,
            'token': token,
            'optionsJson': optionsJson
        });
    }
}
