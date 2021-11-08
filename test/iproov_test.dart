import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iproov_flutter/iproov_flutter.dart';

// same as the payload used inside the [IProov] class
Map<String, dynamic> _launchPayload({
  required String streamingUrl,
  required String token,
  required Options options,
}) =>
    {
      'streamingURL': streamingUrl,
      'token': token,
      'optionsJSON': json.encode(options)
    };

void main() {
  late MethodChannelMock cameraChannelMock;
  late MethodChannelMock streamChannelMock;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    cameraChannelMock = MethodChannelMock(
        channelName: 'com.iproov.sdk', methods: {'launch': {}});
    streamChannelMock = MethodChannelMock(
        channelName: 'com.iproov.sdk.listener', methods: {'listen': {}});
  });

  test('launch starts streaming', () async {
    IProov.launch(
      streamingUrl: 'abc',
      token: '123',
      options: Options(),
      callback: (event) {},
    );
    // check that platform channel methods are called
    expect(cameraChannelMock.log, <Matcher>[
      isMethodCall('launch',
          arguments: _launchPayload(
              streamingUrl: 'abc', token: '123', options: Options()))
    ]);
    expect(streamChannelMock.log,
        <Matcher>[isMethodCall('listen', arguments: null)]);
  });

  // TODO: EventChannel methods for the various IProovEvents
  // References:
  // - https://medium.com/flutter/flutter-platform-channels-ce7f540a104e
  // - https://github.com/flutter/flutter/issues/63465
  // - https://stackoverflow.com/questions/63353885/how-to-test-method-channel-that-call-from-native-to-flutter
  // Some of the proposed solutions were attempted, but couldn't get it to work
  test('decode IProovEvent.connecting', () async {}, skip: true);
  test('decode IProovEvent.connected', () async {}, skip: true);
  test('decode IProovEvent.cancelled', () async {}, skip: true);
  test('decode IProovEvent.progress', () async {}, skip: true);
  test('decode IProovEvent.success', () async {}, skip: true);
  test('decode IProovEvent.failure', () async {}, skip: true);
  test('decode IProovEvent.error', () async {}, skip: true);

  test('launch after subscription closed starts stream again', () async {},
      skip: true);
}

// borrowed from the camera plugin test code
class MethodChannelMock {
  final Duration? delay;
  final MethodChannel methodChannel;
  final Map<String, dynamic> methods;
  final log = <MethodCall>[];

  MethodChannelMock({
    required String channelName,
    this.delay,
    required this.methods,
  }) : methodChannel = MethodChannel(channelName) {
    methodChannel.setMockMethodCallHandler(_handler);
  }

  Future _handler(MethodCall methodCall) async {
    log.add(methodCall);

    if (!methods.containsKey(methodCall.method)) {
      throw MissingPluginException('No implementation found for method '
          '${methodCall.method} on channel ${methodChannel.name}');
    }

    return Future.delayed(delay ?? Duration.zero, () {
      final result = methods[methodCall.method];
      if (result is Exception) {
        throw result;
      }

      return Future.value(result);
    });
  }
}
