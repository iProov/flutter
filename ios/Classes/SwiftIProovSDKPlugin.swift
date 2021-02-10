import Flutter
import iProov
import UIKit

public final class SwiftIProovSDKPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    enum ChannelName: String {
        case event = "com.iproov.sdk.listener"
        case method = "com.iproov.sdk"
    }

    enum FlutterMethod: String {
        case launch
    }

    enum LaunchArguments: String {
        case optionsJSON = "optionsJson"
        case streamingURL = "streamingUrl"
        case token
    }

    enum PluginError {
        case errorFromIProovSDK(LocalizedError)
        case launchArgumentsMissing
        case streamURLArgumentMissingOrEmpty
        case tokenArgumentMissingOrEmpty

        var message: String {
            switch self {
            case let .errorFromIProovSDK(error):
                return error.errorDescription ?? ""
            case .launchArgumentsMissing:
                return "iProov SDK launch arguments missing"
            case .streamURLArgumentMissingOrEmpty:
                return "iProov SDK streamURL arguments missing or empty"
            case .tokenArgumentMissingOrEmpty:
                return "iProov SDK token arguments missing or empty"
            }
        }

        var sinkError: [String: String?] {
            ["event": "error", "exception": message]
        }
    }

    private var sink: FlutterEventSink?

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

    private func handleLaunch(arguments: Any?, result: @escaping FlutterResult) {
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
        if let optionsJSON = arguments[LaunchArguments.optionsJSON.rawValue] {
            print(optionsJSON)
            options = Options() // TODO:
        } else {
            options = Options()
        }

        IProov.launch(streamingURL: streamingURL, token: token, options: options) { [weak self] in
            self?.sink?(self?.sinkEvent(for: $0))
        }

        result(nil)
    }

    private func sinkEvent(for status: Status) -> Any {
        switch status {
        case .connecting:
            return ["event": "connecting"]
        case .connected:
            return ["event": "connected"]
        case let .processing(progress, message):
            return ["event": "processing", "progress": progress, "message": message]
        case let .success(result):
            return ["event": "success", "token": result.token]
        case .cancelled:
            return FlutterEndOfEventStream
        case let .failure(result):
            return ["event": "failure", "token": result.token, "reason": result.reason, "feedbackCode": result.feedbackCode]
        case let .error(error):
            return PluginError.errorFromIProovSDK(error).sinkError
        @unknown default:
            return FlutterMethodNotImplemented
        }
    }
}

public extension SwiftIProovSDKPlugin {
    func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        sink = events
        return nil
    }

    func onCancel(withArguments _: Any?) -> FlutterError? {
        sink = nil
        return nil
    }
}
