import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iproov_flutter/iproov_flutter.dart';

void main() {
  const MethodChannel _channel = MethodChannel('com.iproov.sdk');

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _channel.setMockMethodCallHandler((MethodCall call) async {
      if (call.method == 'launch') return null;
      throw MissingPluginException();
    });
  });

  test('constructor doesn\'t start streaming', () async {
    final iProov = IProov(streamingUrl: 'abc', token: '123');
    expect(iProov.isStreaming, false);
  });

  test('launch starts streaming', () async {
    final iProov = IProov(streamingUrl: 'abc', token: '123');
    iProov.launch((event) {});
    expect(iProov.isStreaming, true);
  });

  test('launch twice throws exception', () async {
    final iProov = IProov(streamingUrl: 'abc', token: '123');
    iProov.launch((event) {});
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
