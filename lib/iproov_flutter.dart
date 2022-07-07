import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:iproov_flutter/events.dart';
import 'package:iproov_flutter/options.dart';

export 'package:iproov_flutter/enums.dart';
export 'package:iproov_flutter/events.dart';
export 'package:iproov_flutter/exceptions.dart';
export 'package:iproov_flutter/options.dart';

const MethodChannel _iProovMethodChannel = MethodChannel('com.iproov.sdk');
const EventChannel _iProovListenerEventChannel = EventChannel('com.iproov.sdk.listener');

class IProov {
  static Stream<IProovEvent> _stream() =>
      _iProovListenerEventChannel.receiveBroadcastStream().map((result) => IProovEvent.fromMap(result));

  static StreamSubscription<IProovEvent>? _subscription;

  /// Launches the iProov face scan.
  ///
  /// You must supply a [streamingUrl] and [token]. You may also provide [options].
  ///
  /// The function returns a [Stream<IProovEvent>] that will emit events
  /// as the scan progresses.
  ///
  /// For further details, see https://github.com/iProov/flutter
  static Stream<IProovEvent> launch({
    required String streamingUrl,
    required String token,
    Options? options,
  }) {
    final stream = _stream();

    _subscription = stream.listen((event) {
      if (event.isFinal) {
        _subscription?.cancel();
        _subscription = null;
      }
    });

    _iProovMethodChannel.invokeMethod('launch',
        {'streamingURL': streamingUrl, 'token': token, if (options != null) 'optionsJSON': json.encode(options)});

    return stream;
  }

  // Private constructor
  IProov._();
}
