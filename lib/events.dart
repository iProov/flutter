import 'package:image/image.dart';

abstract class IProovEvent {
  static const connecting = const IProovEventConnecting();
  static const connected = const IProovEventConnected();
  static const cancelled = const IProovEventCancelled();

  factory IProovEvent.progress(double progress, String message) =
  IProovEventProgress;

  factory IProovEvent.success(String token, Image? frame) = IProovEventSuccess;

  factory IProovEvent.failure(
      String token, String reason, String feedbackCode, Image? frame) = IProovEventFailure;

  factory IProovEvent.error(String reason, String message, String exception) =
  IProovEventError;

  factory IProovEvent.fromMap(Map map) {
    switch (map['event']) {
      case 'connecting':
        return connecting;
      case 'connected':
        return connected;
      case 'processing':
        return IProovEvent.progress(map['progress'], map['message']);
      case 'success':
        Image? frame;
        if (map['frame'] != null) {
          frame = decodePng(map['frame']!);
        }
        return IProovEvent.success(map['token'], frame);
      case 'failure':
        Image? frame;
        if (map['frame'] != null) {
          frame = decodePng(map['frame']!);
        }
        return IProovEvent.failure(map['token'], map['reason'], map['feedbackCode'], frame);
      case 'cancelled':
        return cancelled;
      case 'error':
        return IProovEvent.error(map['reason'], map['message'], map['exception']);
    }
    throw Exception('Invalid event');
  }
}

class IProovEventConnecting implements IProovEvent {
  const IProovEventConnecting();
}

class IProovEventConnected implements IProovEvent {
  const IProovEventConnected();
}

class IProovEventCancelled implements IProovEvent {
  const IProovEventCancelled();
}

class IProovEventProgress implements IProovEvent {
  final double progress;
  final String message;

  const IProovEventProgress(this.progress, this.message);
}

class IProovEventSuccess implements IProovEvent {
  final String token;
  final Image? frame;

  const IProovEventSuccess(this.token, this.frame);
}

class IProovEventFailure implements IProovEvent {
  final String token;
  final String reason;
  final String feedbackCode;
  final Image? frame;

  const IProovEventFailure(this.token, this.reason, this.feedbackCode, this.frame);
}

class IProovEventError implements IProovEvent {
  final String reason;
  final String message;
  final String exception;

  const IProovEventError(this.reason, this.message, this.exception);
}