import Flutter
import iProov
import UIKit

private enum EventKey: String {
    case event
    case error
    case message
    case progress
    case reasons
    case frame
    case title
    case canceler
}

private enum UIEventName: String {
    case not_started
    case started
    case ended
}

private enum EventName: String {
    case canceled
    case connecting
    case connected
    case error
    case processing
    case failure
    case success
}

public final class SwiftIProovSDKPlugin: NSObject {

    private enum PluginError: LocalizedError {
        case invalidArguments
        case invalidStreamingURL
        case invalidToken
        case invalidOptions

        var errorDescription: String? {
            switch self {
            case .invalidArguments:
                return "No arguments were provided."
            case .invalidStreamingURL:
                return "No streaming URL was provided."
            case .invalidToken:
                return "No token was provided."
            case .invalidOptions:
                return "Invalid options were provided."
            }
        }
    }

    private var eventListener: EventListener?
    private var uiEventListener: EventListener?
    private var session: Session?
    private var pendingError: Error? // Ideally this would be IProovError? but it crashes the compiler =/


    func registerEventChannel(with registrar: FlutterPluginRegistrar) {
        let eventChannel = FlutterEventChannel(name: "com.iproov.sdk.listener", binaryMessenger: registrar.messenger())
        eventListener = EventListener(
            onListen: {  eventSink in
                //Flush any pending error when the stream handler connects:
                if let pendingError = self.pendingError as? IProovError {
                    eventSink(Status.error(pendingError).serialized)
                    eventSink(FlutterEndOfEventStream)
                    self.pendingError = nil
                }

                return nil
            },
            onCancel: {
                self.session?.cancel()
                self.session = nil
                return nil
            }
        )
        eventChannel.setStreamHandler(eventListener)
    }

    func registerUIEventChannel(with registrar: FlutterPluginRegistrar) {
        let eventChannel = FlutterEventChannel(name: "com.iproov.sdk.uiListener", binaryMessenger: registrar.messenger())
        uiEventListener = EventListener(
            onListen: { eventSink in return nil},
            onCancel: { return nil }
        )
        eventChannel.setStreamHandler(uiEventListener)
    }

    func handleLaunch(arguments: Any?) throws -> Session {
        guard let arguments = arguments as? [String: String] else {
            throw PluginError.invalidArguments
        }

        guard let streamingURLString = arguments["streamingURL"],
              let streamingURL = URL(string: streamingURLString) else {
            throw PluginError.invalidStreamingURL
        }

        guard let token = arguments["token"] else {
            throw PluginError.invalidToken
        }

        let options: Options

        if let optionsJSONString = arguments["optionsJSON"] {
            guard let dict = try? JSONSerialization.jsonObject(with: optionsJSONString.data(using: .utf8)!, options: []) as? [String: Any] else {
                throw PluginError.invalidOptions
            }

            options = Options.from(flutterJSON: dict)
        } else {
            options = Options()
        }

        options.viewDelegate = self

        return IProov.launch(streamingURL: streamingURL, token: token, options: options) { [weak self] status in
            self?.eventListener?.sendEvent(event: status.serialized)
            if status.isFinished {
                self?.eventListener?.endOfEventStream()
            }
        }
    }
}

extension SwiftIProovSDKPlugin: IProovViewDelegate {
    public func willPresentIProovView() {
        self.uiEventListener?.sendEvent(event: ["uiEvent" : UIEventName.not_started.rawValue])
    }

    public func didPresentIProovView() {
        self.uiEventListener?.sendEvent(event: ["uiEvent" : UIEventName.started.rawValue])
    }

    public func didDismissIProovView() {
        self.uiEventListener?.sendEvent(event: ["uiEvent" : UIEventName.ended.rawValue])
    }
}

extension SwiftIProovSDKPlugin: FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.iproov.sdk", binaryMessenger: registrar.messenger())
        let instance = SwiftIProovSDKPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        instance.registerEventChannel(with: registrar)
        instance.registerUIEventChannel(with: registrar)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "launch":
            do {
                setEnvironment()
                session = try handleLaunch(arguments: call.arguments)
            } catch { // Re-route all launch errors via the event sink, to avoid needing to handle them async on launch
                pendingError = IProovError.unexpectedError("Flutter Error: " + error.localizedDescription)
            }

            result(nil)
        case "keyPair.sign":
            guard let flutterData = call.arguments as? FlutterStandardTypedData else {
                result(FlutterError(code: "INVALID",
                                    message: "Invalid argument passed",
                                    details: nil))
                return
            }
            let signature = IProov.keyPair.sign(data: flutterData.data)
            result(signature)
        case "keyPair.publicKey.getPem":
            result(IProov.keyPair.publicKey.pem)
        case "keyPair.publicKey.getDer":
            result(IProov.keyPair.publicKey.der)
        case "cancel":
            let cancelResult = session?.cancel()
            result(cancelResult)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func setEnvironment(){
        let sharedPrefs = UserDefaults(suiteName: "iproov_environment_prefs")
        sharedPrefs?.set("flutter", forKey: "environment")
    }
}

class EventListener: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?

    // Closures to capture external behavior
    private let onListenHandler: (@escaping FlutterEventSink) -> FlutterError?
    private let onCancelHandler: () -> FlutterError?

    init(onListen: @escaping (FlutterEventSink) -> FlutterError?, onCancel: @escaping () -> FlutterError?) {
        self.onListenHandler = onListen
        self.onCancelHandler = onCancel
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return onListenHandler(events)
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return onCancelHandler()
    }

    func sendEvent(event: [String : Any]?) {
        eventSink?(event)
    }

    func endOfEventStream() {
        eventSink?(FlutterEndOfEventStream)
    }
}

private extension Status {
    var serialized: [String: Any]? {
        switch self {
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
                EventKey.frame.rawValue: result.frame?.pngData()?.flutterData as Any
            ]
        case let .canceled(canceler):
            return [
                EventKey.event.rawValue: EventName.canceled.rawValue,
                EventKey.canceler.rawValue: canceler.stringValue
            ]
        case let .failure(result):
            return [
                EventKey.event.rawValue: EventName.failure.rawValue,
                EventKey.reasons.rawValue: result.reasons.map { $0.toDictionary() },
                EventKey.frame.rawValue: result.frame?.pngData()?.flutterData as Any
            ]
        case let .error(error):
            return error.serialized as [String : Any]
        @unknown default:
            return nil
        }
    }

}

extension iProov.FailureReason {
    func toDictionary() -> [String: Any] {
        return [
            "feedbackCode": self.feedbackCode,
            "description": self.localizedDescription
        ]
    }
}

private extension Options {

    // Handle any Flutter-specific requirements, e.g. custom fonts
    static func from(flutterJSON dict: [String : Any]) -> Options {

        let options = Options.from(dictionary: dict)

        // Handle custom fonts:
        if let fontPath = dict["font"] as? String {
            installFont(path: fontPath)
            let fontName = String(fontPath.split(separator: "/").last!.split(separator: ".").first!)
            options.font = fontName
        }

        return options
    }

    // Load font from Flutter assets:
    private static func installFont(path: String) {
        let fontKey = FlutterDartProject.lookupKey(forAsset: path)
        guard let url = Bundle.main.url(forResource: fontKey, withExtension: nil),
              let fontData = try? Data(contentsOf: url),
              let dataProvider = CGDataProvider(data: fontData as CFData) else {
            fatalError("Failed to load font at path: \(path)")
        }

        let fontRef = CGFont(dataProvider)
        CTFontManagerRegisterGraphicsFont(fontRef!, nil)
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
            return "server"
        case .userTimeout:
            return "user_timeout"
        case .notSupported:
            return "unsupported_device"
        case .unexpectedError:
            fallthrough
        @unknown default:
            return "unexpected_error"
        }
    }

}

private extension Canceler {
    var stringValue: String {
        switch self {
        case .integration: return "app"
        case .user: return "user"
        @unknown default:
            fatalError()
        }
    }
}
