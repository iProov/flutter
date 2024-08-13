package com.iproov.sdk

import android.content.Context
import android.graphics.Bitmap
import com.iproov.sdk.api.OptionsBridge
import com.iproov.sdk.api.IProov
import com.iproov.sdk.api.exception.*
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.flow.onSubscription
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlinx.coroutines.cancel
import kotlinx.coroutines.withContext


class IProovSDKPlugin : FlutterPlugin {

    companion object {
        val TAG = IProovSDKPlugin::class.simpleName
    }

    private val coroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    private lateinit var eventChannel: EventChannel
    private lateinit var uiEventChannel: EventChannel
    private lateinit var methodChannel: MethodChannel

    private var eventSink: EventChannel.EventSink? = null
    private var uiEventSink: EventChannel.EventSink? = null
    private var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding? = null

    private var sessionStateJob: Job? = null
    private var sessionUIStateJob: Job? = null
    private var pendingException: IProovException? = null

    private fun observeSessionState(session: IProov.Session, whenReady: (() -> Unit)? = null) {
        sessionStateJob?.cancel()
        sessionStateJob = coroutineScope.launch(Dispatchers.IO) {
            kotlin.runCatching {
                session.state
                    .onSubscription { whenReady?.invoke() }
                    .collect { state ->
                        withContext(Dispatchers.Main) {
                            when (state) {
                                is IProov.State.Connecting -> {
                                    eventSink?.success(hashMapOf("event" to "connecting"))
                                }

                                is IProov.State.Connected -> {
                                    eventSink?.success(hashMapOf("event" to "connected"))
                                }

                                is IProov.State.Processing -> {
                                    eventSink?.success(
                                        hashMapOf(
                                            "event" to "processing",
                                            "progress" to state.progress,
                                            "message" to state.message
                                        )
                                    )
                                }

                                is IProov.State.Success -> {
                                    val frameArray = state.successResult.frame?.let { bmp ->
                                        val stream = ByteArrayOutputStream()
                                        bmp.compress(Bitmap.CompressFormat.PNG, 100, stream)
                                        val byteArray: ByteArray = stream.toByteArray()
                                        bmp.recycle()
                                        byteArray
                                    }

                                    eventSink?.success(
                                        hashMapOf(
                                            "event" to "success",
                                            "frame" to frameArray
                                        )
                                    )
                                    eventSink?.endOfStream()
                                }

                                is IProov.State.Failure -> {
                                    val context = flutterPluginBinding!!.applicationContext

                                    val frameArray = state.failureResult.frame?.let { bmp ->
                                        val stream = ByteArrayOutputStream()
                                        bmp.compress(Bitmap.CompressFormat.PNG, 100, stream)
                                        val byteArray: ByteArray = stream.toByteArray()
                                        bmp.recycle()
                                        byteArray
                                    }

                                    eventSink?.success(
                                        hashMapOf(
                                            "event" to "failure",
                                            "feedbackCode" to state.failureResult.reason.feedbackCode,
                                            "reason" to context.getString(state.failureResult.reason.description),
                                            "frame" to frameArray
                                        )
                                    )
                                    eventSink?.endOfStream()
                                }

                                is IProov.State.Error -> {
                                    eventSink?.success(state.exception.serialize())
                                    eventSink?.endOfStream()
                                }

                                is IProov.State.Canceled -> {
                                    eventSink?.success(
                                        hashMapOf(
                                            "event" to "canceled",
                                            "canceler" to state.canceler.name.lowercase()
                                        )
                                    )
                                    eventSink?.endOfStream()
                                }

                                else -> {

                                }
                            }
                        }
                    }
            }
        }
    }

    private fun observeSessionUIState(session: IProov.Session) {
        sessionUIStateJob?.cancel()
        sessionUIStateJob = coroutineScope.launch(Dispatchers.IO) {
            kotlin.runCatching {
                session.uiState
                    .collect { sessionUIState ->
                        withContext(Dispatchers.Main) {
                            when (sessionUIState) {
                                IProov.UIState.NotStarted -> {
                                    uiEventSink?.success(hashMapOf("uiEvent" to "not_started"))
                                }

                                IProov.UIState.Started -> {
                                    uiEventSink?.success(hashMapOf("uiEvent" to "started"))
                                }

                                IProov.UIState.Ended -> {
                                    uiEventSink?.success(hashMapOf("uiEvent" to "ended"))
                                    uiEventSink?.endOfStream()
                                }
                            }
                        }
                    }
            }
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
                        val signature = IProov.getKeyPair(context!!).sign(data)
                        result.success(signature)
                    } else {
                        result.error("INVALID", "Invalid argument passed", null)
                    }
                }

                "keyPair.publicKey.getPem" -> result.success(IProov.getKeyPair(context!!).publicKey.pem)
                "keyPair.publicKey.getDer" -> result.success(IProov.getKeyPair(context!!).publicKey.der)
                "cancel" -> cancelSession()
                else -> result.notImplemented()
            }
        }

        private fun cancelSession() {
            coroutineScope.launch {
                IProov.session?.cancel()
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
                        if (options.font is IProov.Options.Font.PathFont) {
                            options.font = IProov.Options.Font.PathFont(
                                getFontPath((options.font as IProov.Options.Font.PathFont).path)
                            )
                        }
                    }

                    coroutineScope.launch {
                        IProov.createSession(context, streamingUrl, token, options).let { session ->
                            // Observe first, then start
                            observeSession(session) {
                                session.start()
                            }
                        }
                    }
                }
            }
        }
    }

    private fun observeSession(session: IProov.Session, whenReady: (() -> Unit)? = null) {
        observeSessionState(session, whenReady)
        observeSessionUIState(session)
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
                coroutineScope.launch {
                    IProov.session?.cancel()
                }
                eventSink = null
            }
        })

        uiEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "com.iproov.sdk.uiListener")
        uiEventChannel.setStreamHandler(object : EventChannel.StreamHandler {

            override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                uiEventSink = sink
            }

            override fun onCancel(arguments: Any?) {
                uiEventSink = null
            }
        })
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        uiEventChannel.setStreamHandler(null)
        coroutineScope.cancel()
        this.flutterPluginBinding = null
    }

    private fun getFontPath(assetPath: String): String {
        val loader = FlutterInjector.instance().flutterLoader()
        return loader.getLookupKeyForAsset(assetPath)
    }
}

fun IProovException.serialize(): HashMap<String, String?> {
    val exceptionName = when (this) {
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