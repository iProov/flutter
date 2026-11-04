abstract class IProovException implements Exception {
  final String title;
  final String? message;
  IProovException(this.title, [this.message]);

  factory IProovException.error(String error, String title, String? message) {
    switch (error) {
      case 'capture_already_active':
        return CaptureAlreadyActiveException(title);
      case 'session_cannot_be_started_twice':
        return SessionCannotBeStartedTwiceException(title);
      case 'consent_required':
        return ConsentRequiredException(title);
      case 'network':
        return NetworkException(title, message);
      case 'camera_permission':
        return CameraPermissionException(title);
      case 'server':
        return ServerException(title, message);
      case 'multi_window_unsupported':
        return MultiWindowUnsupportedException(title);
      case 'camera':
        return CameraException(title, message);
      case 'unsupported_device':
        return UnsupportedDeviceException(title);
      case 'invalid_options':
        return InvalidOptionsException(title);
      case 'user_timeout':
        return UserTimeoutException(title);
      case 'unsupported_os_version':
        return UnsupportedOSVersionException(title, message);
      case 'unsupported_sdk_version':
        return UnsupportedSDKVersionException(title, message);
    }

    return UnexpectedErrorException(title, message);
  }
}

class CaptureAlreadyActiveException extends IProovException {
  CaptureAlreadyActiveException(String title) : super(title);
}

// Android only
class SessionCannotBeStartedTwiceException extends IProovException {
  SessionCannotBeStartedTwiceException(String title) : super(title);
}

class ConsentRequiredException extends IProovException {
  ConsentRequiredException(String title) : super(title);
}

class NetworkException extends IProovException {
  NetworkException(String title, String? message) : super(title, message);
}

class CameraPermissionException extends IProovException {
  CameraPermissionException(String title) : super(title);
}

class ServerException extends IProovException {
  ServerException(String title, String? message) : super(title, message);
}

class UnexpectedErrorException extends IProovException {
  UnexpectedErrorException(String title, String? message) : super(title, message);
}

// iOS only
class UserTimeoutException extends IProovException {
  UserTimeoutException(String title) : super(title);
}

// Android only
class MultiWindowUnsupportedException extends IProovException {
  MultiWindowUnsupportedException(String title) : super(title);
}

// Android only
class CameraException extends IProovException {
  CameraException(String title, String? message) : super(title, message);
}

class UnsupportedDeviceException extends IProovException {
  UnsupportedDeviceException(String title) : super(title);
}

// Android only
class InvalidOptionsException extends IProovException {
  InvalidOptionsException(String title) : super(title);
}

class UnsupportedOSVersionException extends IProovException {
  UnsupportedOSVersionException(String title, String? message) : super(title, message);
}

class UnsupportedSDKVersionException extends IProovException {
  UnsupportedSDKVersionException(String title, String? message) : super(title, message);
}
