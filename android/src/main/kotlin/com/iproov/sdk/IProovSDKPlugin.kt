package com.iproov.sdk

import android.content.Context
import android.util.Log
import androidx.annotation.NonNull
import com.iproov.sdk.core.exception.IProovException
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.SupervisorJob
import org.json.JSONException
import org.json.JSONObject
import java.io.BufferedReader

/** IProovSDKPlugin */
class IProovSDKPlugin: FlutterPlugin {

    companion object {
        const val METHOD_CHANNEL_IPROOV_NAME = "com.iproov.sdk"
        const val METHOD_LAUNCH = "launch"
        const val METHOD_LAUNCH_PARAM_STREAMING_URL = "streamingUrl"
        const val METHOD_LAUNCH_PARAM_TOKEN = "token"
        const val METHOD_LAUNCH_PARAM_OPTIONS_JSON = "optionsJson"
        const val METHOD_ERROR_NO_ATTACHED_CONTEXT = "METHOD_ERROR_NO_ATTACHED_CONTEXT"
        const val METHOD_ERROR_MISSING_OR_EMPTY_ARGUMENT = "MISSING_OR_EMPTY_ARGUMENT"
        const val METHOD_LAUNCH_ERROR_OPTIONS_JSON = "ERROR_OPTIONS_JSON"

        const val EVENT_CHANNEL_NAME = "com.iproov.sdk.listener"
        const val EVENT_ON_CONNECTING = "onConnecting"
        const val EVENT_ON_CONNECTED = "onConnected"
        const val EVENT_ON_CANCELLED = "onCancelled"
    }

    private lateinit var listenerEventChannel: EventChannel
    private lateinit var iProovMethodChannel: MethodChannel

    private var listenerEventSink: EventChannel.EventSink? = null
    private var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding? = null

    private val job = SupervisorJob()

    // Callbacks ----

    private val iProovListener = object : IProov.Listener {
        override fun onConnecting() { listenerEventSink?.success(EVENT_ON_CONNECTING) }
        override fun onConnected() { listenerEventSink?.success(EVENT_ON_CONNECTED) }
        override fun onProcessing(progress: Double, message: String?) { listenerEventSink?.success(hashMapOf("progress" to progress, "message" to message)) }
        override fun onSuccess(result: IProov.SuccessResult) { listenerEventSink?.success(result.toString()) }
        override fun onFailure(result: IProov.FailureResult) { listenerEventSink?.success(result.toString()) }
        override fun onCancelled() { listenerEventSink?.error(EVENT_ON_CANCELLED, EVENT_ON_CANCELLED, EVENT_ON_CANCELLED) }
        override fun onError(e: IProovException) { listenerEventSink?.error(e.javaClass.simpleName, e.message, e.toString()) }
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
            val optionsJson: String? = call.argument(METHOD_LAUNCH_PARAM_OPTIONS_JSON)//convertToAndroid(call.argument(METHOD_LAUNCH_PARAM_OPTIONS_JSON))

            when {
                context == null -> {
                    result.error(METHOD_ERROR_NO_ATTACHED_CONTEXT, METHOD_ERROR_NO_ATTACHED_CONTEXT, null)
                }
                streamingUrl.isNullOrEmpty() -> {
                    result.error(METHOD_ERROR_MISSING_OR_EMPTY_ARGUMENT, METHOD_LAUNCH_PARAM_STREAMING_URL, METHOD_LAUNCH_PARAM_STREAMING_URL)
                }
                token.isNullOrEmpty() -> {
                    result.error(METHOD_ERROR_MISSING_OR_EMPTY_ARGUMENT, METHOD_LAUNCH_PARAM_TOKEN, METHOD_LAUNCH_PARAM_TOKEN)
                }
                else -> {

                    Log.w("launch", "url=$streamingUrl token=$token options=$optionsJson")
                    if (optionsJson.isNullOrEmpty()) {
                        IProov.launch(context, streamingUrl!!, token!!)
                    } else {
                        try {
                            val json = JSONObject(optionsJson)
                            val options = OptionsFromJson.fromJson(context, json)!!

                            val certResId = options.network.certificates[0]
                            val stream = context.resources.openRawResource(certResId)
                            val reader = BufferedReader(stream.reader())
                            val content = StringBuffer()
                            try {
                                var line = reader.readLine()
                                while (line != null) {
                                    content.append(line)
                                    line = reader.readLine()
                                }
                            } finally {
                                reader.close()
                            }

                            Log.w("launch cert", "contents=$content")

                            IProov.launch(context, streamingUrl!!, token!!, options)
                        } catch (ex: JSONException) {
                            Log.w("launch bang", "ex=$ex")
                            result.error(METHOD_LAUNCH_ERROR_OPTIONS_JSON, ex.message, optionsJson)
                        }
                    }
                }
            }
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
                if (listenerEventSink == null) return
                IProov.registerListener(iProovListener)
            }

            override fun onCancel(arguments: Any?) {
                if (listenerEventSink == null) return
                IProov.unregisterListener(iProovListener)
                listenerEventSink = null
            }
        })
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        iProovMethodChannel.setMethodCallHandler(null)
        this.flutterPluginBinding = null
    }
}