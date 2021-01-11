abstract class IProovException implements Exception {
  final String title; // TODO: Title is not currently being populated from either iOS or Android, pending SDK updates
  final String? message;
  IProovException(this.title, [this.message]);

  factory IProovException.error(String error, String title, String? message) {
    switch (error) {
      case "capture_already_active":
        return CaptureAlreadyActiveException(title);
      case "network":
        return NetworkException(title, message);
      case "camera_permission":
        return CameraPermissionException(title);
      case "server":
        return ServerException(title, message);
      case "listener_not_registered":
        return ListenerNotRegisteredException(title);
      case "multi_window_unsupported":
        return MultiWindowUnsupportedException(title);
      case "camera":
        return CameraException(title, message);
      case "face_detector":
        return FaceDetectorException(title, message);
      case "unsupported_device":
        return UnsupportedDeviceException(title);
      case "invalid_options":
        return InvalidOptionsException(title);
    }

    return UnexpectedErrorException(title, message);
  }
}

class CaptureAlreadyActiveException extends IProovException {
  CaptureAlreadyActiveException(String title) : super(title);
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

class ListenerNotRegisteredException extends IProovException {  // Android only
  ListenerNotRegisteredException(String title) : super(title);
}

class MultiWindowUnsupportedException extends IProovException {  // Android only
  MultiWindowUnsupportedException(String title) : super(title);
}

class CameraException extends IProovException {  // Android only
  CameraException(String title, String? message) : super(title, message);
}

class FaceDetectorException extends IProovException {  // Android only
  FaceDetectorException(String title, String? message) : super(title, message);
}

class UnsupportedDeviceException extends IProovException { // Android only
  UnsupportedDeviceException(String title) : super(title);
}

class InvalidOptionsException extends IProovException {  // Android only
  InvalidOptionsException(String title) : super(title);
}
