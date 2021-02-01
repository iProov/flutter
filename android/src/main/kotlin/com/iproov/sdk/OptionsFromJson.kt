package com.iproov.sdk

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.util.Base64
import androidx.annotation.ColorInt
import com.iproov.sdk.cameray.Orientation
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

internal object OptionsFromJson {

    fun fromJson(context: Context, json: JSONObject?): IProov.Options {
        val options = IProov.Options()
        if (json == null) return options
        options.ui = uiOptionsFromJson(context, json.optJSONObject("ui"))
        options.capture = captureOptionsFromJson(json.optJSONObject("capture"))
        options.network = networkOptionsFromJson(context, json.optJSONObject("network"))
        return options
    }

    private fun uiOptionsFromJson(context: Context, json: JSONObject?): IProov.Options.UI {
        val ui = IProov.Options.UI()
        if (json == null) return ui
        ui.autoStartDisabled = json.optBoolean("auto_start_disabled", ui.autoStartDisabled)
        ui.filter = optFilter(json, "filter", ui.filter)
        ui.lineColor = optColor(json, "line_color", ui.lineColor)
        ui.backgroundColor = optColor(json, "background_color", ui.backgroundColor)
        ui.loadingTintColor = optColor(json, "loading_tint_color", ui.loadingTintColor)
        ui.notReadyTintColor = optColor(json, "not_ready_tint_color", ui.notReadyTintColor)
        ui.livenessTintColor = optColor(json, "liveness_tint_color", ui.livenessTintColor)
        ui.title = json.optString("title", ui.title)
        ui.fontPath = json.optString("font_path", ui.fontPath)
        ui.fontResource = optFontResource(context, json, "font_resource")
        ui.scanLineDisabled = json.optBoolean("scan_line_disabled", ui.scanLineDisabled)
        ui.enableScreenshots = json.optBoolean("enable_screenshots", ui.enableScreenshots)
        ui.orientation = optOrientation(json, "orientation", ui.orientation)
        ui.logoImageResource = optDrawableResource(context, json, "logo_image_resource")
        ui.activityCompatibilityRequestCode = optInteger(json, "activity_compatibility_request_code", ui.activityCompatibilityRequestCode)
        return ui
    }

    private fun captureOptionsFromJson(json: JSONObject?): IProov.Options.Capture {
        val capture = IProov.Options.Capture()
        if (json == null) return capture
        capture.camera = optCamera(json, "camera", capture.camera)
        capture.faceDetector = optFaceDetector(json, "face_detector", capture.faceDetector)
        capture.maxYaw = optFloat(json, "max_yaw", capture.maxYaw)
        capture.maxRoll = optFloat(json, "max_roll", capture.maxRoll)
        capture.maxPitch = optFloat(json, "max_pitch", capture.maxPitch)
        return capture
    }

    private fun networkOptionsFromJson(context: Context, json: JSONObject?): IProov.Options.Network {
        val network = IProov.Options.Network()
        if (json == null) return network
        network.path = json.optString("path", network.path)
        network.timeoutSecs = json.optInt("timeout", network.timeoutSecs)
        network.certificates = optCertificates(context, json, "certificates", network.certificates)
        return network
    }

    private fun optCertificates(context: Context, json: JSONObject, key: String, fallback: List<Int>): List<Int> {
        val certificates = json.optJSONArray(key) ?: return fallback
        val newCertificates: MutableList<Int> = mutableListOf()
        for (index in 0 until certificates.length()) {
            val obj = certificates[index]
            if (obj is String) {
                val newCertResId = context.resources.getIdentifier(obj, null, context.packageName)
                newCertificates.add(newCertResId)
            }
        }
        return newCertificates
    }

    private fun optFontResource(context: Context, json: JSONObject, key: String): Int {
        val resourceName = json.optString(key) ?: return -1
        val resId = context.resources.getIdentifier(resourceName, "font", context.packageName)
        return if (resId == 0) -1 else resId
    }

    private fun optDrawableResource(context: Context, json: JSONObject, key: String): Int {
        val resourceName = json.optString(key) ?: return -1
        val resId = context.resources.getIdentifier(resourceName, "drawable", context.packageName)
        return if (resId == 0) -1 else resId
    }

    @ColorInt
    @Throws(JSONException::class)
    fun getColor(array: JSONArray): Int {
        return if (array.length() > 2) {
            val redComponent = java.lang.Float.valueOf(array.getString(0))
            val greenComponent = java.lang.Float.valueOf(array.getString(1))
            val blueComponent = java.lang.Float.valueOf(array.getString(2))
            Color.argb(255, (redComponent * 255).toInt(), (greenComponent * 255).toInt(), (blueComponent * 255).toInt())
        } else throw JSONException("Array too short")
    }

    @Throws(JSONException::class)
    fun getFloat(jsonObject: JSONObject, name: String?): Float {
        return jsonObject.getDouble(name).toFloat()
    }

    fun optFloat(jsonObject: JSONObject, name: String?, defaultValue: Float): Float {
        return jsonObject.optDouble(name, defaultValue.toDouble()).toFloat()
    }

    @Throws(JSONException::class)
    fun getBitmap(jsonObject: JSONObject, name: String?): Bitmap {
        val dataDecoded = Base64.decode(jsonObject.getString(name), Base64.DEFAULT)
        return BitmapFactory.decodeByteArray(dataDecoded, 0, dataDecoded.size)
    }

    fun optBitmap(jsonObject: JSONObject, name: String?, defaultValue: Bitmap?): Bitmap? {
        return try {
            getBitmap(jsonObject, name)
        } catch (e: JSONException) {
            defaultValue
        }
    }

    fun optFilter(json: JSONObject, key: String?, fallback: IProov.Filter): IProov.Filter {
        val filterStr = json.optString(key, toString(fallback))
        return toFilter(filterStr, fallback)
    }

    @ColorInt
    fun optColor(json: JSONObject, key: String?, @ColorInt fallback: Int): Int {
        return if (json.has(key)) Color.parseColor(json.optString(key)) else fallback
    }

    fun optOrientation(json: JSONObject, key: String?, fallback: Orientation): Orientation {
        val orientationStr = json.optString(key, toString(fallback))
        return toOrientation(orientationStr, fallback)
    }

    fun optCamera(json: JSONObject, key: String?, fallback: IProov.Camera): IProov.Camera {
        val cameraStr = json.optString(key, toString(fallback))
        return toCamera(cameraStr, fallback)
    }

    fun optFaceDetector(json: JSONObject, key: String?, fallback: IProov.FaceDetector): IProov.FaceDetector {
        val faceDetectorStr = json.optString(key, toString(fallback))
        return toFaceDetector(faceDetectorStr, fallback)
    }

    fun optFloat(json: JSONObject, key: String, fallback: Float?): Float? {
        // create new Float object, so null fallback isn't converted to primative value
        return if (json.has(key) && !json.isNull(key)) java.lang.Float.valueOf(json.optDouble(key).toFloat()) else fallback
    }

    fun optInteger(json: JSONObject, key: String, fallback: Int?): Int? {
        // create new Integer object, so null fallback isn't converted to primative value
        return if (json.has(key) && !json.isNull(key)) Integer.valueOf(json.optInt(key)) else fallback
    }

    private fun toFilter(str: String, fallback: IProov.Filter): IProov.Filter {
        return when (str) {
            "classic" -> IProov.Filter.CLASSIC
            "shaded" -> IProov.Filter.SHADED
            "vibrant" -> IProov.Filter.VIBRANT
            else -> fallback
        }
    }

    private fun toString(filter: IProov.Filter): String {
        return when (filter) {
            IProov.Filter.CLASSIC -> "classic"
            IProov.Filter.SHADED -> "shaded"
            IProov.Filter.VIBRANT -> "vibrant"
            else -> "classic"
        }
    }

    private fun toOrientation(orientation: String, fallback: Orientation): Orientation {
        return when (orientation) {
            "portrait" -> Orientation.PORTRAIT
            "landscape" -> Orientation.LANDSCAPE
            "reverse_portrait" -> Orientation.REVERSE_PORTRAIT
            "reverse_landscape" -> Orientation.REVERSE_LANDSCAPE
            else -> fallback
        }
    }

    private fun toString(orientation: Orientation): String {
        return when (orientation) {
            Orientation.PORTRAIT -> "portrait"
            Orientation.LANDSCAPE -> "landscape"
            Orientation.REVERSE_PORTRAIT -> "reverse_portrait"
            Orientation.REVERSE_LANDSCAPE -> "reverse_landscape"
            else -> "portrait"
        }
    }

    private fun toCamera(camera: String, fallback: IProov.Camera): IProov.Camera {
        return when (camera) {
            "front" -> IProov.Camera.FRONT
            "external" -> IProov.Camera.EXTERNAL
            else -> fallback
        }
    }

    private fun toString(camera: IProov.Camera): String {
        return when (camera) {
            IProov.Camera.FRONT -> "front"
            IProov.Camera.EXTERNAL -> "external"
            else -> "front"
        }
    }

    private fun toFaceDetector(faceDetector: String, fallback: IProov.FaceDetector): IProov.FaceDetector {
        return when (faceDetector) {
            "classic" -> IProov.FaceDetector.CLASSIC
            "blazeface" -> IProov.FaceDetector.BLAZEFACE
            "mlkit", "firebase" -> IProov.FaceDetector.ML_KIT
            "auto" -> IProov.FaceDetector.AUTO
            else -> fallback
        }
    }

    private fun toString(faceDetector: IProov.FaceDetector): String {
        return when (faceDetector) {
            IProov.FaceDetector.AUTO -> "auto"
            IProov.FaceDetector.CLASSIC -> "classic"
            IProov.FaceDetector.BLAZEFACE -> "blazeface"
            IProov.FaceDetector.ML_KIT -> "mlkit"
            else -> "auto"
        }
    }
}