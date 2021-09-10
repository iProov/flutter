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

const MethodChannel _iProovMethodChannel =
    const MethodChannel('com.iproov.sdk');

const EventChannel _iProovListenerEventChannel =
    EventChannel('com.iproov.sdk.listener');

class IProov {
  IProov({
    required this.streamingUrl,
    required this.token,
    this.options = const Options(),
  });

  /// Streaming URL to use
  final String streamingUrl;

  /// Token obtained from the API
  final String token;

  /// Configuration options
  final Options options;

  /// Whether a streaming session is already im progress
  bool get isStreaming => _subscription != null;

  Stream<IProovEvent> _events() => _iProovListenerEventChannel
      .receiveBroadcastStream()
      .map((result) => IProovEvent.fromMap(result));

  StreamSubscription<IProovEvent>? _subscription;

  /// Launch the verification process
  ///
  /// The [IProovEventCallback] callback will be called multiple times
  ///
  /// When the process is completed, the last event is returned
  Future<IProovEvent> launch(IProovEventCallback callback) {
    final completer = Completer<IProovEvent>();
    if (isStreaming) {
      throw AssertionError('A streaming session is already in progress');
    }

    _subscription = _events().listen((event) {
      if (event.isFinal) {
        _subscription?.cancel();
        _subscription = null;
        completer.complete(event);
      }
      callback(event);
    });

    _iProovMethodChannel.invokeMethod('launch', {
      'streamingURL': streamingUrl,
      'token': token,
      'optionsJSON': json.encode(options)
    });
    return completer.future;
  }
}
