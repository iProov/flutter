import 'package:image/image.dart';
import 'package:iproov_flutter/exceptions.dart';

abstract class IProovEvent {
  bool get isFinal;

  factory IProovEvent.fromMap(Map map) {
    switch (map['event']) {
      case 'connecting':
        return const IProovEventConnecting();

      case 'connected':
        return const IProovEventConnected();

      case 'processing':
        return IProovEventProcessing(map['progress'], map['message']);

      case 'success':
        final frameData = map['frame'];
        final frame = frameData != null ? decodePng(frameData) : null;
        return IProovEventSuccess(map['token'], frame);

      case 'failure':
        final frameData = map['frame'];
        final frame = frameData != null ? decodePng(frameData) : null;
        return IProovEventFailure(map['token'], map['reason'], map['feedbackCode'], frame);

      case 'cancelled':
        return const IProovEventCancelled();

      case 'error':
        return IProovEventError.create(map['error'], map['title'], map['message']);
    }
    throw Exception('Invalid event');
  }
}

/// The SDK is connecting to the server. You should provide an indeterminate progress indicator
/// to let the user know that the connection is taking place.
class IProovEventConnecting implements IProovEvent {
  @override
  get isFinal => false;

  const IProovEventConnecting();
}

/// The SDK has connected, and the iProov user interface will now be displayed. You should hide
/// any progress indication at this point.
class IProovEventConnected implements IProovEvent {
  @override
  get isFinal => false;

  const IProovEventConnected();
}

/// The user cancelled iProov, either by pressing the close button at the top right, or sending
/// the app to the background.
class IProovEventCancelled implements IProovEvent {
  @override
  get isFinal => true;

  const IProovEventCancelled();
}

/// The SDK will update your app with the progress of streaming to the server and authenticating
/// the user. This will be called multiple time as the progress updates.
class IProovEventProcessing implements IProovEvent {
  @override
  get isFinal => false;

  /// The progress of the streaming/processing, between 0.0 and 1.0.
  final double progress;

  /// A message that can be displayed directly to the user relating to the current progress state.
  final String message;

  const IProovEventProcessing(this.progress, this.message);
}

/// The user was successfully verified/enrolled and the token has been validated.
class IProovEventSuccess implements IProovEvent {
  @override
  get isFinal => true;

  /// The token passed back will be the same as the one passed in to the original call to `iProov.launch`.
  final String token;

  /// An optional image containing a single frame of the user, if enabled for your service provider.
  final Image? frame;

  const IProovEventSuccess(this.token, this.frame);
}

/// The user was not successfully verified/enrolled, as their identity could not be verified,
/// or there was another issue with their verification/enrollment.
class IProovEventFailure implements IProovEvent {
  @override
  get isFinal => true;

  /// The token passed back will be the same as the one passed in to the original call to `iProov.launch`.
  final String token;

  /// The reason for the failure which can be displayed directly to the user.
  final String reason;

  /// The feedback code relating to this error. For a list of possible failure codes, see:
  /// * https://github.com/iProov/ios#handling-failures--errors
  /// * https://github.com/iProov/android#handling-failures--errors
  final String feedbackCode;

  /// An optional image containing a single frame of the user, if enabled for your service provider.
  final Image? frame;

  const IProovEventFailure(this.token, this.reason, this.feedbackCode, this.frame);
}

/// The user was not successfully verified/enrolled due to an error (e.g. lost internet connection).
class IProovEventError implements IProovEvent {
  @override
  get isFinal => true;

  final IProovException error;

  const IProovEventError(this.error);

  factory IProovEventError.create(String error, String title, String? message) =>
      IProovEventError(IProovException.error(error, title, message));
}
