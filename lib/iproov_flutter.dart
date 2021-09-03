import 'dart:convert';

export 'package:iproov_flutter/options.dart';
export 'package:iproov_flutter/enums.dart';
export 'package:iproov_flutter/events.dart';
export 'package:iproov_flutter/exceptions.dart';

import 'package:flutter/services.dart';
import 'package:iproov_flutter/options.dart';
import 'package:iproov_flutter/events.dart';

class IProov {
  static const MethodChannel _iProovMethodChannel =
      const MethodChannel('com.iproov.sdk');

  static const EventChannel _iProovListenerEventChannel =
      EventChannel('com.iproov.sdk.listener');

  static final events = _iProovListenerEventChannel
      .receiveBroadcastStream()
      .map((result) => IProovEvent.fromMap(result));

  static launch(String streamingUrl, String token, [Options? options]) => _iProovMethodChannel
      .invokeMethod('launch', {
        'streamingURL': streamingUrl,
        'token': token,
        'optionsJSON': json.encode(options)
      });

  // Private constructor
  IProov._();
}


