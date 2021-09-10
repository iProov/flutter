import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:iproov_flutter/events.dart';
import 'package:iproov_flutter/options.dart';

export 'package:iproov_flutter/enums.dart';
export 'package:iproov_flutter/events.dart';
export 'package:iproov_flutter/exceptions.dart';
export 'package:iproov_flutter/options.dart';

typedef IProovEventCallback = void Function(IProovEvent);

class IProov {
  static const MethodChannel _iProovMethodChannel =
      const MethodChannel('com.iproov.sdk');

  static const EventChannel _iProovListenerEventChannel =
      EventChannel('com.iproov.sdk.listener');

  // Private constructor
  IProov._();

  /// If only an instance can ever be created by the client, expose this singleton
  static final instance = IProov._();

  Stream<IProovEvent> _events() => _iProovListenerEventChannel
      .receiveBroadcastStream()
      .map((result) => IProovEvent.fromMap(result));

  StreamSubscription<IProovEvent>? _subscription;

  void launch(String streamingUrl, String token,
      {Options? options, required IProovEventCallback callback}) {
    // ? Is it valid for the client to call launch() more than once?
    // ? If not, some defensive code with an assertion error is appropriate here
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
