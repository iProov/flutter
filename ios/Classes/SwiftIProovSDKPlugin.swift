import Flutter
import iProov
import UIKit

public final class SwiftIProovSDKPlugin: NSObject {
    private enum ChannelName: String {
        case event = "com.iproov.sdk.listener"
        case method = "com.iproov.sdk"
    }

    private enum FlutterMethod: String {
        case launch
    }

    private enum LaunchArguments: String {
        case optionsJSON
        case streamingURL
        case token
    }

    private enum SinkEventKey: String {
        case event
        case exception
        case feedbackCode
        case message
        case progress
        case reason
        case token
        case frame
    }

    private enum SinkEventValue: String {
        case cancelled
        case connecting
        case connected
        case error
        case processing
        case failure
        case success
    }

    private enum PluginError {
        case noArguments
        case missingArgument(String)
        case iProovError(IProovError)
        case invalidOptions

        var sinkError: [String: String?] {

            let errorMessage: String

            switch self {
            case .noArguments:
                errorMessage = "No arguments provided"
            case let .missingArgument(arg):
                errorMessage = "\(arg) argument missing or empty"
            case let .iProovError(error):
                errorMessage = error.localizedDescription
            case .invalidOptions:
                errorMessage = "Invalid options"
            }

            return [
                SwiftIProovSDKPlugin.SinkEventKey.event.rawValue: SwiftIProovSDKPlugin.SinkEventValue.error.rawValue,
                SwiftIProovSDKPlugin.SinkEventKey.exception.rawValue: errorMessage,
            ]
        }
    }

    private var sink: FlutterEventSink?
}

extension SwiftIProovSDKPlugin: FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: ChannelName.method.rawValue, binaryMessenger: registrar.messenger())
        let instance = SwiftIProovSDKPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        FlutterEventChannel(name: ChannelName.event.rawValue, binaryMessenger: registrar.messenger())
            .setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch FlutterMethod(rawValue: call.method) {
        case .launch:
            handleLaunch(arguments: call.arguments) { error in
                sink?(error)
            }
            result(nil)
        case .none:
            result(FlutterMethodNotImplemented)
        }
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
            return launchError(PluginError.noArguments.sinkError)
        }

        guard let streamingURL = arguments[LaunchArguments.streamingURL.rawValue], !streamingURL.isEmpty else {
            return launchError(PluginError.missingArgument(LaunchArguments.streamingURL.rawValue).sinkError)
        }

        guard let token = arguments[LaunchArguments.token.rawValue], !token.isEmpty else {
            return launchError(PluginError.missingArgument(LaunchArguments.token.rawValue).sinkError)
        }

        let options: Options

        if let optionsJSONString = arguments[LaunchArguments.optionsJSON.rawValue] {
            guard let dict = try? JSONSerialization.jsonObject(with: optionsJSONString.data(using: .utf8)!, options: []) as? [String: Any] else {
                return launchError(PluginError.invalidOptions)
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
            return [SinkEventKey.event.rawValue: SinkEventValue.connecting.rawValue]
        case .connected:
            return [SinkEventKey.event.rawValue: SinkEventValue.connected.rawValue]
        case let .processing(progress, message):
            return [
                SinkEventKey.event.rawValue: SinkEventValue.processing.rawValue,
                SinkEventKey.progress.rawValue: progress,
                SinkEventKey.message.rawValue: message,
            ]
        case let .success(result):
            return [
                SinkEventKey.event.rawValue: SinkEventValue.success.rawValue,
                SinkEventKey.token.rawValue: result.token,
                SinkEventKey.frame.rawValue: result.frame?.pngData()?.flutterData as Any
            ]
        case .cancelled:
            return [SinkEventKey.event.rawValue: SinkEventValue.cancelled.rawValue]
        case let .failure(result):
            return [
                SinkEventKey.event.rawValue: SinkEventValue.failure.rawValue,
                SinkEventKey.token.rawValue: result.token,
                SinkEventKey.reason.rawValue: result.reason,
                SinkEventKey.feedbackCode.rawValue: result.feedbackCode,
                SinkEventKey.frame.rawValue: result.frame?.pngData()?.flutterData as Any
            ]
        case let .error(error):
            return PluginError.iProovError(error).sinkError as [String: Any]
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
