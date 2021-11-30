import Flutter
import iProov
import UIKit

private enum EventKey: String {
    case event
    case error
    case feedbackCode
    case message
    case progress
    case reason
    case token
    case frame
    case title
}

private enum EventName: String {
    case cancelled
    case connecting
    case connected
    case error
    case processing
    case failure
    case success
}

public final class SwiftIProovSDKPlugin: NSObject {
    private var sink: FlutterEventSink?
}

extension SwiftIProovSDKPlugin: FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.iproov.sdk", binaryMessenger: registrar.messenger())
        let instance = SwiftIProovSDKPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        FlutterEventChannel(name: "com.iproov.sdk.listener", binaryMessenger: registrar.messenger())
            .setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

        guard call.method == "launch" else {
            result(FlutterMethodNotImplemented)
            return
        }

        handleLaunch(arguments: call.arguments) { error in
            sink?(error)
        }
        result(nil)
    }
}

extension SwiftIProovSDKPlugin: FlutterStreamHandler {
    public func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        sink = events
        return nil
    }

    public func onCancel(withArguments _: Any?) -> FlutterError? {
        sink = nil
        return nil
    }
}

private extension SwiftIProovSDKPlugin {
    func handleLaunch(arguments: Any?, launchError: (Any) -> Void) {
        guard let arguments = arguments as? [String: String] else {
            return launchError(IProovError.unexpectedError("No arguments"))
        }

        guard let streamingURL = arguments["streamingURL"], !streamingURL.isEmpty else {
            return launchError(IProovError.unexpectedError("Streaming URL missing"))
        }

        guard let token = arguments["token"], !token.isEmpty else {
            return launchError(IProovError.unexpectedError("Token missing"))
        }

        let options: Options

        if let optionsJSONString = arguments["optionsJSON"] {
            guard let dict = try? JSONSerialization.jsonObject(with: optionsJSONString.data(using: .utf8)!, options: []) as? [String: Any] else {
                return launchError(IProovError.unexpectedError("Invalid options"))
            }

            options = Options.from(json: dict)
        } else {
            options = Options()
        }

        IProov.launch(streamingURL: streamingURL, token: token, options: options) { [weak self] in
            self?.sink?(self?.sinkEvent(for: $0))
        }
    }

    func sinkEvent(for status: Status) -> [String: Any]? {
        switch status {
        case .connecting:
            return [EventKey.event.rawValue: EventName.connecting.rawValue]
        case .connected:
            return [EventKey.event.rawValue: EventName.connected.rawValue]
        case let .processing(progress, message):
            return [
                EventKey.event.rawValue: EventName.processing.rawValue,
                EventKey.progress.rawValue: progress,
                EventKey.message.rawValue: message,
            ]
        case let .success(result):
            return [
                EventKey.event.rawValue: EventName.success.rawValue,
                EventKey.token.rawValue: result.token,
                EventKey.frame.rawValue: result.frame?.pngData()?.flutterData as Any
            ]
        case .cancelled:
            return [EventKey.event.rawValue: EventName.cancelled.rawValue]
        case let .failure(result):
            return [
                EventKey.event.rawValue: EventName.failure.rawValue,
                EventKey.token.rawValue: result.token,
                EventKey.reason.rawValue: result.reason,
                EventKey.feedbackCode.rawValue: result.feedbackCode,
                EventKey.frame.rawValue: result.frame?.pngData()?.flutterData as Any
            ]
        case let .error(error):
            return error.serialized as [String : Any]
        @unknown default:
            return nil
        }
    }
}

private extension Data {

    var flutterData: FlutterStandardTypedData? {
        FlutterStandardTypedData(bytes: self)
    }

}

private extension IProovError {

    var serialized: [String: String?] {
        var result = [String: String?]()
        result[EventKey.event.rawValue] = "error"
        result[EventKey.error.rawValue] = errorName
        result[EventKey.title.rawValue] = localizedTitle
        result[EventKey.message.rawValue] = localizedMessage
        return result
    }

    private var errorName: String {
        switch self {
        case .captureAlreadyActive:
            return "capture_already_active"
        case .networkError:
            return "network"
        case .cameraPermissionDenied:
            return "camera_permission"
        case .serverError:
            return "server_error"
        case .unexpectedError:
            fallthrough
        @unknown default:
            return "unexpected_error"
        }
    }

}
