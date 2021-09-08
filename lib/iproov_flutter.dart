import 'dart:async';
import 'dart:convert';

export 'package:iproov_flutter/options.dart';
export 'package:iproov_flutter/enums.dart';
export 'package:iproov_flutter/events.dart';
export 'package:iproov_flutter/exceptions.dart';

import 'package:flutter/services.dart';
import 'package:iproov_flutter/options.dart';
import 'package:iproov_flutter/events.dart';

typedef IProovEventCallback = void Function(IProovEvent);

class IProov {
  static const MethodChannel _iProovMethodChannel =
      const MethodChannel('com.iproov.sdk');

  static const EventChannel _iProovListenerEventChannel =
      EventChannel('com.iproov.sdk.listener');

  // Private constructor
  IProov._();

  /// If only an instance can ever be created by the client, this can be done with this singleton
  static final instance = IProov._();

  Stream<IProovEvent> _events() => _iProovListenerEventChannel
      .receiveBroadcastStream()
      .map((result) => IProovEvent.fromMap(result));

  StreamSubscription<IProovEvent>? _subscription;

  void launch(String streamingUrl, String token,
      {Options? options, required IProovEventCallback callback}) {
    // Some defensive code needed if client calls launch more than one time (and this is not allowed)
    if (_subscription != null) {
      throw AssertionError('launch() method was called more than once');
    }

    _subscription = _events().listen((event) {
      if (event.isFinal) {
        _subscription?.cancel();
      }
      callback(event);
    });

    _iProovMethodChannel.invokeMethod('launch', {
      'streamingURL': streamingUrl,
      'token': token,
      'optionsJSON': json.encode(options)
    });
  }

  void dispose() {
    _subscription?.cancel();
  }
}
