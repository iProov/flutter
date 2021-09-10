import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iproov_flutter/iproov_flutter.dart';

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

  test('constructor doesn\'t start streaming', () async {
    final iProov = IProov(streamingUrl: 'abc', token: '123');
    expect(iProov.isStreaming, false);
  });

  test('launch starts streaming', () async {
    final iProov = IProov(streamingUrl: 'abc', token: '123');
    await iProov.launch((event) {});
    expect(iProov.isStreaming, true);
    // check that platform channel methods are called
    expect(cameraChannelMock.log,
        <Matcher>[isMethodCall('launch', arguments: iProov.launchPayload())]);
    expect(streamChannelMock.log,
        <Matcher>[isMethodCall('listen', arguments: null)]);
  });

  test('launch twice throws exception', () async {
    final iProov = IProov(streamingUrl: 'abc', token: '123');
    await iProov.launch((event) {});
    expect(() => iProov.launch((event) {}), throwsAssertionError);
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
