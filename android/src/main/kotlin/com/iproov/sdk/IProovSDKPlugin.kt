package com.iproov.sdk

import android.content.Context
import android.util.Log
import androidx.annotation.NonNull
import com.iproov.sdk.bridge.OptionsBridge
import com.iproov.sdk.core.exception.CameraException
import com.iproov.sdk.core.exception.CameraPermissionException
import com.iproov.sdk.core.exception.CaptureAlreadyActiveException
import com.iproov.sdk.core.exception.FaceDetectorException
import com.iproov.sdk.core.exception.IProovException
import com.iproov.sdk.core.exception.ListenerNotRegisteredException
import com.iproov.sdk.core.exception.MultiWindowUnsupportedException
import com.iproov.sdk.core.exception.NetworkException
import com.iproov.sdk.core.exception.ServerException
import com.iproov.sdk.core.exception.UnexpectedErrorException
import com.iproov.sdk.core.exception.UnsupportedDeviceException
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.lang.Exception

class IProovSDKPlugin: FlutterPlugin {

    companion object {
        val TAG = IProovSDKPlugin::class.simpleName
        const val METHOD_CHANNEL_IPROOV_NAME = "com.iproov.sdk"
        const val METHOD_LAUNCH = "launch"
        const val METHOD_LAUNCH_PARAM_STREAMING_URL = "streamingURL"
        const val METHOD_LAUNCH_PARAM_TOKEN = "token"
        const val METHOD_LAUNCH_PARAM_OPTIONS_JSON = "optionsJSON"
        const val METHOD_ERROR_NO_ATTACHED_CONTEXT = "METHOD_ERROR_NO_ATTACHED_CONTEXT"
        const val EVENT_CHANNEL_NAME = "com.iproov.sdk.listener"
    }

    private lateinit var listenerEventChannel: EventChannel
    private lateinit var iProovMethodChannel: MethodChannel

    private var listenerEventSink: EventChannel.EventSink? = null
    private var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding? = null

    // Callbacks ----

    private val iProovListener = object : IProov.Listener {
        override fun onConnecting() {
            listenerEventSink?.success(hashMapOf(
                    "event" to "connecting"
            ))
        }

        override fun onConnected() {
            listenerEventSink?.success(hashMapOf(
                    "event" to "connected"
            ))
        }

        override fun onProcessing(progress: Double, message: String?) {
            listenerEventSink?.success(hashMapOf(
                    "event" to "processing",
                    "progress" to progress,
                    "message" to message
            ))
        }

        override fun onSuccess(result: IProov.SuccessResult) {
            listenerEventSink?.success(hashMapOf(
                    "event" to "success",
                    "token" to result.token
            ))
        }

        override fun onFailure(result: IProov.FailureResult) {
            listenerEventSink?.success(hashMapOf(
                    "event" to "failure",
                    "token" to result.token,
                    "reason" to result.reason,
                    "feedbackCode" to result.feedbackCode
            )) }

        override fun onCancelled() {
            listenerEventSink?.success(hashMapOf(
                    "event" to "cancelled"
            ))
        }
        override fun onError(e: IProovException) {

            val exceptionName = when(e) {
                is CaptureAlreadyActiveException -> "capture_already_active"
                is NetworkException -> "network"
                is CameraPermissionException -> "camera_permission"
                is ServerException -> "server"
                is ListenerNotRegisteredException -> "listener_not_registered"
                is MultiWindowUnsupportedException -> "multi_window_unsupported"
                is CameraException -> "camera"
                is FaceDetectorException -> "face_detector"
                is UnsupportedDeviceException -> "unsupported_device"
                else -> "unexpected_error" // includes UnexpectedErrorException
            }

            listenerEventSink?.success(hashMapOf(
                    "event" to "error",
                    "error" to exceptionName,
                    "title" to e.getReason(),
                    "message" to e.message
            ))
        }
    }

    private val methodCallHandler = object : MethodChannel.MethodCallHandler {
        override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
            when (call.method) {
                METHOD_LAUNCH -> handleLaunch(call, result)
                else -> result.notImplemented()
            }
        }

        private fun handleLaunch(call: MethodCall, result: MethodChannel.Result) {
            val context: Context? = flutterPluginBinding?.applicationContext
            val streamingUrl: String? = call.argument(METHOD_LAUNCH_PARAM_STREAMING_URL)
            val token: String? = call.argument(METHOD_LAUNCH_PARAM_TOKEN)
            val optionsJson: String? = call.argument(METHOD_LAUNCH_PARAM_OPTIONS_JSON)

            result.success(null)
            when {
                context == null -> {
                    handleException(IllegalArgumentException(METHOD_ERROR_NO_ATTACHED_CONTEXT))
                }
                streamingUrl.isNullOrEmpty() -> {
                    handleException(IllegalArgumentException(METHOD_LAUNCH_PARAM_STREAMING_URL))
                }
                token.isNullOrEmpty() -> {
                    handleException(IllegalArgumentException(METHOD_LAUNCH_PARAM_TOKEN))
                }
                optionsJson.isNullOrEmpty() -> {
                    try {
                        IProov.launch(context, streamingUrl, token)
                    } catch (e: Exception) {
                        handleException(e)
                    }
                }
                else -> {
                    try {
                        val json = JSONObject(optionsJson)
                        val options = OptionsBridge.fromJson(context, json)
                        IProov.launch(context, streamingUrl, token, options)
                    } catch (e: Exception) {
                        handleException(e)
                    }
                }
            }
        }

        private fun handleException(exception: Exception) {
            listenerEventSink?.success(hashMapOf("event" to "error", "exception" to exception.toString()))
        }
    }

    // Functions ----

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        this.flutterPluginBinding = flutterPluginBinding

        iProovMethodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, METHOD_CHANNEL_IPROOV_NAME)
        iProovMethodChannel.setMethodCallHandler(methodCallHandler)

        listenerEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, EVENT_CHANNEL_NAME)
        listenerEventChannel.setStreamHandler(object : EventChannel.StreamHandler {

            override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                listenerEventSink = sink
            }

            override fun onCancel(arguments: Any?) {
                listenerEventSink = null
            }
        })

        IProov.registerListener(iProovListener)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        IProov.unregisterListener(iProovListener)
        iProovMethodChannel.setMethodCallHandler(null)
        listenerEventChannel.setStreamHandler(null)
        this.flutterPluginBinding = null
    }
}
