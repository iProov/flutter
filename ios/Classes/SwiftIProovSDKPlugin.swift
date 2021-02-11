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

    private enum SinkEventKey: String {
        case event
        case exception
        case feedbackCode
        case message
        case progress
        case reason
        case token
    }

    private enum SinkEventValue: String {
        case connecting
        case connected
        case error
        case processing
        case failure
        case success
    }

    fileprivate enum LaunchArguments: String {
        case optionsJSON = "optionsJson"
        case streamingURL = "streamingUrl"
        case token
    }

    fileprivate enum PluginError {
        case errorFromIProovSDK(LocalizedError)
        case launchArgumentsMissing
        case streamURLArgumentMissingOrEmpty
        case tokenArgumentMissingOrEmpty
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
            handleLaunch(arguments: call.arguments, result: result)
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
    func handleLaunch(arguments: Any?, result: @escaping FlutterResult) {
        guard let arguments = arguments as? [String: String] else {
            return result(PluginError.launchArgumentsMissing.sinkError)
        }

        guard let streamingURL = arguments[LaunchArguments.streamingURL.rawValue], !streamingURL.isEmpty else {
            return result(PluginError.streamURLArgumentMissingOrEmpty.sinkError)
        }

        guard let token = arguments[LaunchArguments.token.rawValue], !token.isEmpty else {
            return result(PluginError.tokenArgumentMissingOrEmpty.sinkError)
        }

        let options: Options
        if arguments[LaunchArguments.optionsJSON.rawValue] != nil {
            options = Options() // TODO, uncomment upon next SDK release Options.from(jsonString: optionsJSON)
        } else {
            options = Options()
        }

        IProov.launch(streamingURL: streamingURL, token: token, options: options) { [weak self] in
            self?.sink?(self?.sinkEvent(for: $0))
        }

        result(nil)
    }

    func sinkEvent(for status: Status) -> Any {
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
            ]
        case .cancelled:
            return FlutterEndOfEventStream
        case let .failure(result):
            return [SinkEventKey.event.rawValue: SinkEventValue.failure.rawValue,
                    SinkEventKey.token.rawValue: result.token,
                    SinkEventKey.reason.rawValue: result.reason,
                    SinkEventKey.feedbackCode.rawValue: result.feedbackCode]
        case let .error(error):
            return PluginError.errorFromIProovSDK(error).sinkError
        @unknown default:
            return FlutterMethodNotImplemented
        }
    }
}

private extension SwiftIProovSDKPlugin.PluginError {
    var message: String {
        let arg: String

        switch self {
        case let .errorFromIProovSDK(error):
            return error.errorDescription ?? ""
        case .launchArgumentsMissing:
            arg = "launch"
        case .streamURLArgumentMissingOrEmpty:
            arg = SwiftIProovSDKPlugin.LaunchArguments.streamingURL.rawValue
        case .tokenArgumentMissingOrEmpty:
            arg = SwiftIProovSDKPlugin.LaunchArguments.token.rawValue
        }

        return "iProov SDK \(arg) arguments missing or empty"
    }

    var sinkError: [String: String?] {
        [
            SwiftIProovSDKPlugin.SinkEventKey.event.rawValue: SwiftIProovSDKPlugin.SinkEventValue.error.rawValue,
            SwiftIProovSDKPlugin.SinkEventKey.exception.rawValue: message,
        ]
    }
}
