package com.iproov.sdk

import android.content.Context
import android.graphics.Bitmap
import com.iproov.sdk.bridge.OptionsBridge
import com.iproov.sdk.core.exception.*
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.ByteArrayOutputStream


class IProovSDKPlugin: FlutterPlugin {

    companion object {
        val TAG = IProovSDKPlugin::class.simpleName
    }

    private lateinit var eventChannel: EventChannel
    private lateinit var methodChannel: MethodChannel

    private var eventSink: EventChannel.EventSink? = null
    private var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding? = null
    private val launcher = IProovCallbackLauncher()
    private var pendingException: IProovException? = null

    private val iProovListener = object : IProovCallbackLauncher.Listener {
        override fun onConnecting() {
            eventSink?.success(hashMapOf(
                "event" to "connecting"
            ))
        }

        override fun onConnected() {
            eventSink?.success(hashMapOf(
                "event" to "connected"
            ))
        }

        override fun onProcessing(progress: Double, message: String?) {
            eventSink?.success(hashMapOf(
                "event" to "processing",
                "progress" to progress,
                "message" to message
            ))
        }

        override fun onSuccess(result: IProov.SuccessResult) {
            val frameArray = result.frame?.let { bmp ->
                val stream = ByteArrayOutputStream()
                bmp.compress(Bitmap.CompressFormat.PNG, 100, stream)
                val byteArray: ByteArray = stream.toByteArray()
                bmp.recycle()
                byteArray
            }

            eventSink?.success(hashMapOf(
                "event" to "success",
                "frame" to frameArray
            ))
            eventSink?.endOfStream()
        }

        override fun onFailure(result: IProov.FailureResult) {
            val context = flutterPluginBinding!!.applicationContext

            val frameArray = result.frame?.let { bmp ->
                val stream = ByteArrayOutputStream()
                bmp.compress(Bitmap.CompressFormat.PNG, 100, stream)
                val byteArray: ByteArray = stream.toByteArray()
                bmp.recycle()
                byteArray
            }

            eventSink?.success(hashMapOf(
                "event" to "failure",
                "feedbackCode" to result.reason.feedbackCode,
                "reason" to context.getString(result.reason.description),
                "frame" to frameArray
            ))
            eventSink?.endOfStream()
        }

        override fun onCancelled(canceller: IProov.Canceller) {
            eventSink?.success(hashMapOf(
                "event" to "cancelled",
                "canceller" to canceller.name.lowercase()
            ))
            eventSink?.endOfStream()
        }

        override fun onError(exception: IProovException) {
            eventSink?.success(exception.serialize())
            eventSink?.endOfStream()
        }
    }

    private val methodCallHandler = object : MethodChannel.MethodCallHandler {
        override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
            val context: Context? = flutterPluginBinding?.applicationContext
            when (call.method) {
                "launch" -> {
                    try {
                        handleLaunch(call)
                    } catch (e: UnexpectedErrorException) {
                        // Re-route any synchronous launch exceptions to be handled async by the error event handler
                        pendingException = e
                    }
                }
                "keyPair.sign" -> {
                    val data = call.arguments
                    if (data is ByteArray) {
                        val signature = launcher.getKeyPair(context!!).sign(data)
                        result.success(signature)
                    } else {
                        result.error("INVALID", "Invalid argument passed", null)
                    }
                }
                "keyPair.publicKey.getPem" -> result.success(launcher.getKeyPair(context!!).publicKey.pem)
                "keyPair.publicKey.getDer" -> result.success(launcher.getKeyPair(context!!).publicKey.der)
                else -> result.notImplemented()
            }
        }

        private fun handleLaunch(call: MethodCall) {
            val context = flutterPluginBinding!!.applicationContext
            val streamingUrl: String? = call.argument("streamingURL")
            val token: String? = call.argument("token")
            val optionsJson: String? = call.argument("optionsJSON")

            when {
                streamingUrl == null -> {
                    throw UnexpectedErrorException(context, "Flutter Error: No streaming URL was provided.")
                }
                token == null -> {
                    throw UnexpectedErrorException(context, "Flutter Error: No token was provided.")
                }
                else -> {
                    var options = IProov.Options()

                    if (optionsJson != null) {
                        try {
                            val json = JSONObject(optionsJson)
                            options = OptionsBridge.fromJson(context, json)
                        } catch (e: Exception) {
                            throw UnexpectedErrorException(context, "Flutter Error: Invalid options were provided.")
                        }
                    }

                    if (options.font != null) { // Remap custom font paths to assets path
                        if (options.font is IProov.Options.Font.PathFont){
                            options.font = IProov.Options.Font.PathFont(
                                getFontPath((options.font as IProov.Options.Font.PathFont).path)
                            )
                        }
                    }

                    launcher.launch(context, streamingUrl, token, options)
                }
            }
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        this.flutterPluginBinding = flutterPluginBinding

        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.iproov.sdk")
        methodChannel.setMethodCallHandler(methodCallHandler)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "com.iproov.sdk.listener")
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {

            override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                eventSink = sink

                if (pendingException != null) {
                    sink?.success(pendingException!!.serialize())
                    sink?.endOfStream()
                    pendingException = null
                }
            }

            override fun onCancel(arguments: Any?) {
                launcher.currentSession()?.cancel()
                eventSink = null
            }
        })

        launcher.listener = iProovListener
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        launcher.listener = null
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        this.flutterPluginBinding = null
    }

    private fun getFontPath(assetPath: String): String {
        val loader = FlutterInjector.instance().flutterLoader()
        return loader.getLookupKeyForAsset(assetPath)
    }
}

fun IProovException.serialize(): HashMap<String, String?> {
    val exceptionName = when(this) {
        is CaptureAlreadyActiveException -> "capture_already_active"
        is NetworkException -> "network"
        is CameraPermissionException -> "camera_permission"
        is ServerException -> "server"
        is MultiWindowUnsupportedException -> "multi_window_unsupported"
        is CameraException -> "camera"
        is FaceDetectorException -> "face_detector"
        is UnsupportedDeviceException -> "unsupported_device"
        is InvalidOptionsException -> "invalid_options"
        else -> "unexpected_error" // includes UnexpectedErrorException
    }

    return hashMapOf(
        "event" to "error",
        "error" to exceptionName,
        "title" to reason,
        "message" to message
    )
}