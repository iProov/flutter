package com.iproov.flutter_sdk_plugin

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.NonNull
import com.iproov.androidapiclient.AssuranceType
import com.iproov.androidapiclient.ClaimType
import com.iproov.androidapiclient.kotlinfuel.ApiClientFuel
import com.iproov.sdk.IProov
import com.iproov.sdk.bridge.OptionsBridge
import com.iproov.sdk.core.exception.IProovException
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import org.json.JSONException
import org.json.JSONObject


data class Progress(
        val progress: Double,
        val message: String?
)

/** IProovSDKPlugin */
class IProovSDKPlugin: FlutterPlugin {

    companion object {
        const val METHOD_CHANNEL_IPROOV_NAME = "com.iproov.sdk"
        const val METHOD_CHANNEL_TOKEN_NAME = "com.iproov.token"
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

        const val METHOD_GET_TOKEN = "getToken"
        const val METHOD_GET_TOKEN_PARAM_ASSURANCE_TYPE = "assuranceType"
        const val METHOD_GET_TOKEN_PARAM_CLAIM_TYPE = "claimType"
        const val METHOD_GET_TOKEN_PARAM_USERNAME = "username"
    }

    private lateinit var listenerEventChannel: EventChannel
    private lateinit var tokenEventChannel: EventChannel
    private lateinit var iProovMethodChannel: MethodChannel

    private var apiClientFuel: ApiClientFuel? = null
    private var listenerEventSink: EventChannel.EventSink? = null
    private var tokenEventSink: EventChannel.EventSink? = null
    private var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding? = null

    private val job = SupervisorJob()
    private val uiScope = CoroutineScope(Dispatchers.Main + job)

    private val uiThreadHandler: Handler = Handler(Looper.getMainLooper())


    // Callbacks ----

    private val iProovListener = object : IProov.Listener {
        override fun onConnecting() { listenerEventSink?.success(EVENT_ON_CONNECTING) }
        override fun onConnected() { listenerEventSink?.success(EVENT_ON_CONNECTED) }
        override fun onProcessing(progress: Double, message: String?) { listenerEventSink?.success(message) }
        override fun onSuccess(result: IProov.SuccessResult) { listenerEventSink?.success(result.toString()) }
        override fun onFailure(result: IProov.FailureResult) { listenerEventSink?.success(result.toString()) }
        override fun onCancelled() { listenerEventSink?.error(EVENT_ON_CANCELLED, EVENT_ON_CANCELLED, EVENT_ON_CANCELLED) }
        override fun onError(e: IProovException) { listenerEventSink?.error(e.javaClass.simpleName, e.message, e.toString()) }
    }

    private val methodCallHandler = object : MethodChannel.MethodCallHandler {
        override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
            when (call.method) {
                METHOD_LAUNCH -> handleLaunch(call, result)
                METHOD_GET_TOKEN -> fetchToken(call, result)
                else -> result.notImplemented()
            }
        }

        private fun handleLaunch(call: MethodCall, result: MethodChannel.Result) {
            val context: Context? = flutterPluginBinding?.applicationContext
            val streamingUrl: String = Constants.BASE_URL //call.argument(METHOD_LAUNCH_PARAM_STREAMING_URL)
            val token: String? = call.argument(METHOD_LAUNCH_PARAM_TOKEN)
            val optionsJson: String? = call.argument(METHOD_LAUNCH_PARAM_OPTIONS_JSON)

            when {
                context == null -> {
                    result.error(METHOD_ERROR_NO_ATTACHED_CONTEXT, METHOD_ERROR_NO_ATTACHED_CONTEXT, null)
                }
//                streamingUrl.isNullOrEmpty() -> {
//                    result.error(METHOD_ERROR_MISSING_OR_EMPTY_ARGUMENT, METHOD_LAUNCH_PARAM_STREAMING_URL, METHOD_LAUNCH_PARAM_STREAMING_URL)
//                }
                token.isNullOrEmpty() -> {
                    result.error(METHOD_ERROR_MISSING_OR_EMPTY_ARGUMENT, METHOD_LAUNCH_PARAM_TOKEN, METHOD_LAUNCH_PARAM_TOKEN)
                }
                else -> {

                    Log.w("launch", "url=" + streamingUrl + " token=" + token)
                    if (optionsJson.isNullOrEmpty()) {
                        IProov.launch(context, streamingUrl, token)
                    } else {
                        try {
                            val json = JSONObject(optionsJson)
                            val options = OptionsBridge.fromJson(context, json)
                            IProov.launch(context, streamingUrl, token, options)
                        } catch (ex: JSONException) {
                            result.error(METHOD_LAUNCH_ERROR_OPTIONS_JSON, ex.message, optionsJson)
                        }
                    }
                }
            }
        }

        private fun fetchToken(call: MethodCall, result: MethodChannel.Result) {
            val context: Context? = flutterPluginBinding?.applicationContext
            val assuranceTypeName: String? = call.argument(METHOD_GET_TOKEN_PARAM_ASSURANCE_TYPE)
            val claimTypeName: String? = call.argument(METHOD_GET_TOKEN_PARAM_CLAIM_TYPE)
            val username: String? = call.argument(METHOD_GET_TOKEN_PARAM_USERNAME)
            when {
                context == null -> {
                    result.error(METHOD_ERROR_NO_ATTACHED_CONTEXT, METHOD_ERROR_NO_ATTACHED_CONTEXT, null)
                }
                assuranceTypeName.isNullOrEmpty() -> {
                    result.error(METHOD_ERROR_MISSING_OR_EMPTY_ARGUMENT, METHOD_GET_TOKEN_PARAM_ASSURANCE_TYPE, METHOD_GET_TOKEN_PARAM_ASSURANCE_TYPE)
                }
                claimTypeName.isNullOrEmpty() -> {
                    result.error(METHOD_ERROR_MISSING_OR_EMPTY_ARGUMENT, METHOD_GET_TOKEN_PARAM_CLAIM_TYPE, METHOD_GET_TOKEN_PARAM_CLAIM_TYPE)
                }
                username.isNullOrEmpty() -> {
                    result.error(METHOD_ERROR_MISSING_OR_EMPTY_ARGUMENT, METHOD_GET_TOKEN_PARAM_USERNAME, METHOD_GET_TOKEN_PARAM_USERNAME)
                }
                else -> {

                    Log.w("getToken", "assuranceType=" + assuranceTypeName + " claimType=" + claimTypeName)
                    val assuranceType: AssuranceType = AssuranceType.valueOf(assuranceTypeName)
                    val claimType: ClaimType = ClaimType.valueOf(claimTypeName)

                    if (apiClientFuel == null) {
                        apiClientFuel = ApiClientFuel(
                                context,
                                Constants.BASE_URL,
                                Constants.API_KEY,
                                Constants.SECRET
                        )
                    }

                    uiScope.launch(Dispatchers.IO) {
                        try {
                            val token = apiClientFuel!!.getToken(
                                    AssuranceType.GENUINE_PRESENCE,
                                    claimType,
                                    username)

                            uiThreadHandler.post{ tokenEventSink?.success(token) }
                        } catch (e: Exception) {
                            uiThreadHandler.post{ tokenEventSink?.error(e.javaClass.simpleName, e.message, e.toString()) }
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

        tokenEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, METHOD_CHANNEL_TOKEN_NAME)
        tokenEventChannel.setStreamHandler(object : EventChannel.StreamHandler {

            override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                tokenEventSink = sink
                if (tokenEventSink == null) return
            }

            override fun onCancel(arguments: Any?) {
                if (tokenEventSink == null) return
                tokenEventSink = null
            }
        })
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        iProovMethodChannel.setMethodCallHandler(null)
        this.flutterPluginBinding = null
    }
}