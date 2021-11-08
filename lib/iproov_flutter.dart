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

const MethodChannel _iProovMethodChannel = MethodChannel('com.iproov.sdk');

const EventChannel _iProovListenerEventChannel =
    EventChannel('com.iproov.sdk.listener');

class IProov {
  static Stream<IProovEvent> _events() => _iProovListenerEventChannel
      .receiveBroadcastStream()
      .map((result) => IProovEvent.fromMap(result));

  static StreamSubscription<IProovEvent>? _subscription;

  /// Launch the iProov face scan. You must supply a [streamingUrl] and
  /// [token]. You may also provide [options].
  ///
  /// The [IProovEventCallback] callback will be called multiple times as the
  /// scan progresses.
  ///
  /// For further details, see https://github.com/iProov/flutter
  static launch({
    required String streamingUrl,
    required String token,
    Options? options,
    required IProovEventCallback callback,
  }) {
    _subscription = _events().listen((event) {
      if (event.isFinal) {
        _subscription?.cancel();
        _subscription = null;
      }
      callback(event);
    });

    _iProovMethodChannel.invokeMethod('launch', {
      'streamingURL': streamingUrl,
      'token': token,
      if (options != null) 'optionsJSON': json.encode(options)
    });
  }

  // Private constructor
  IProov._();
}
