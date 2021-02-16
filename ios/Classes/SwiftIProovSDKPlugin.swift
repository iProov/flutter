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
            options = Options() // Options.from(jsonString: optionsJSON)
        } else {
            options = Options()
        }

        IProov.launch(streamingURL: streamingURL, token: token, options: options) { [weak self] in
            guard let self = self else {
                return
            }

            guard let event = self.sinkEvent(for: $0) else {
                return
            }

            self.sink?(event)
        }

        result(nil)
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
            ]
        case .cancelled:
            return [SinkEventKey.event.rawValue: SinkEventValue.cancelled.rawValue]
        case let .failure(result):
            return [SinkEventKey.event.rawValue: SinkEventValue.failure.rawValue,
                    SinkEventKey.token.rawValue: result.token,
                    SinkEventKey.reason.rawValue: result.reason,
                    SinkEventKey.feedbackCode.rawValue: result.feedbackCode]
        case let .error(error):
            return PluginError.errorFromIProovSDK(error).sinkError as [String: Any]
        @unknown default:
            return nil
        }
    }
}

private extension SwiftIProovSDKPlugin.PluginError {
    var sinkError: [String: String?] {
        let arg: String
        switch self {
        case let .errorFromIProovSDK(error):
            arg = error.errorDescription ?? ""
        case .launchArgumentsMissing:
            arg = "launch"
        case .streamURLArgumentMissingOrEmpty:
            arg = SwiftIProovSDKPlugin.LaunchArguments.streamingURL.rawValue
        case .tokenArgumentMissingOrEmpty:
            arg = SwiftIProovSDKPlugin.LaunchArguments.token.rawValue
        }

        return [
            SwiftIProovSDKPlugin.SinkEventKey.event.rawValue: SwiftIProovSDKPlugin.SinkEventValue.error.rawValue,
            SwiftIProovSDKPlugin.SinkEventKey.exception.rawValue: "iProov SDK \(arg) arguments missing or empty",
        ]
    }
}
