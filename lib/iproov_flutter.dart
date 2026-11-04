import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:iproov_flutter/events.dart';
import 'package:iproov_flutter/exceptions.dart';
import 'package:iproov_flutter/options.dart';

export 'package:iproov_flutter/enums.dart';
export 'package:iproov_flutter/events.dart';
export 'package:iproov_flutter/exceptions.dart';
export 'package:iproov_flutter/options.dart';

const _iProovMethodChannel = MethodChannel('com.iproov.sdk');
const _iProovListenerEventChannel = EventChannel('com.iproov.sdk.listener');
const _iProovUIListenerEventChannel = EventChannel('com.iproov.sdk.uiListener');

class IProov {
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
    _iProovMethodChannel.invokeMethod('launch', {
      'streamingURL': streamingUrl,
      'token': token,
      if (options != null) 'optionsJSON': json.encode(options)
    });

    return _iProovListenerEventChannel.receiveBroadcastStream().map((result) => IProovEvent.fromMap(result));
  }

  static Stream<IProovUIEvent> uiEvent() {
    return _iProovUIListenerEventChannel.receiveBroadcastStream().map((uiResult) => IProovUIEvent.fromMap(uiResult));
  }

  static final keyPair = KeyPair();

  // Private constructor
  IProov._();

  /// Cancels the currently active iProov session, if any.
  static Future<void> cancel() async {
    await _iProovMethodChannel.invokeMethod<void>('cancel');
  }

  static Future<bool> isSessionActive() async {
    return await _iProovMethodChannel.invokeMethod<bool>('isSessionActive') ?? false;
  }

  /// Returns the version string of the underlying native iProov SDK.
  static Future<String> nativeSdkVersion() async {
    return await _invokeMethod('nativeSdkVersion');
  }
}

Future<T> _invokeMethod<T>(String method, [dynamic arguments]) async {
  try {
    return await _iProovMethodChannel.invokeMethod(method, arguments);
  } on PlatformException catch (e) {
    throw IProovException.error(e.code, e.message ?? '', e.details as String?);
  }
}

class KeyPair {
  final publicKey = PublicKey();

  Future<Uint8List> sign(Uint8List data) async {
    return await _invokeMethod('keyPair.sign', data);
  }
}

class PublicKey {
  Future<String> getPem() async {
    return await _invokeMethod('keyPair.publicKey.getPem');
  }

  Future<Uint8List> getDer() async {
    return await _invokeMethod('keyPair.publicKey.getDer');
  }
}