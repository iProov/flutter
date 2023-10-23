import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:iproov_flutter/events.dart';
import 'package:iproov_flutter/options.dart';

export 'package:iproov_flutter/enums.dart';
export 'package:iproov_flutter/events.dart';
export 'package:iproov_flutter/exceptions.dart';
export 'package:iproov_flutter/options.dart';

const _iProovMethodChannel = MethodChannel('com.iproov.sdk');
const _iProovListenerEventChannel = EventChannel('com.iproov.sdk.listener');

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
    _iProovMethodChannel.invokeMethod('launch',
        {'streamingURL': streamingUrl, 'token': token, if (options != null) 'optionsJSON': json.encode(options)});

    return _iProovListenerEventChannel.receiveBroadcastStream().map((result) => IProovEvent.fromMap(result));
  }

  static final keyPair = KeyPair();

  // Private constructor
  IProov._();

   static Future<bool> cancel() async {
    return await _iProovMethodChannel.invokeMethod('cancel');
  }
}

class KeyPair {
  final publicKey = PublicKey();

  Future<Uint8List> sign(Uint8List data) async {
    return await _iProovMethodChannel.invokeMethod('keyPair.sign', data);
  }
}

class PublicKey {
  Future<String> getPem() async {
    return await _iProovMethodChannel.invokeMethod('keyPair.publicKey.getPem');
  }

  Future<Uint8List> getDer() async {
    return await _iProovMethodChannel.invokeMethod('keyPair.publicKey.getDer');
  }
}