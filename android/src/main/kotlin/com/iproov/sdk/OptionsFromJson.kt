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
import java.lang.IllegalArgumentException

internal object OptionsFromJson {

    fun fromJson(context: Context, json: JSONObject?): IProov.Options {
        val options = IProov.Options()
        if (json == null) return options
        options.ui = json.optJSONObject("ui")?.optUIOptions(context) ?: options.ui
        options.capture = json.optJSONObject("capture")?.optCaptureOptions() ?: options.capture
        options.network = json.optJSONObject("network")?.networkOptionsFromJson(context) ?: options.network
        return options
    }

    private fun JSONObject.optUIOptions(context: Context): IProov.Options.UI {
        val ui = IProov.Options.UI()
        ui.autoStartDisabled = optBoolean("auto_start_disabled", ui.autoStartDisabled)
        ui.filter = optFilter(ui.filter)
        ui.lineColor = optColor("line_color", ui.lineColor)
        ui.backgroundColor = optColor("background_color", ui.backgroundColor)
        ui.loadingTintColor = optColor("loading_tint_color", ui.loadingTintColor)
        ui.notReadyTintColor = optColor("not_ready_tint_color", ui.notReadyTintColor)
        ui.livenessTintColor = optColor("liveness_tint_color", ui.livenessTintColor)
        ui.title = optString("title", ui.title)
        ui.fontPath = optString("font_path", ui.fontPath)
        ui.fontResource = optFontResource(context)
        ui.scanLineDisabled = optBoolean("scan_line_disabled", ui.scanLineDisabled)
        ui.enableScreenshots = optBoolean("enable_screenshots", ui.enableScreenshots)
        ui.orientation = optOrientation(ui.orientation)
        ui.logoImageResource = optDrawableResource(context, "logo_image_resource")
        ui.activityCompatibilityRequestCode = optInteger("activity_compatibility_request_code", ui.activityCompatibilityRequestCode)
        return ui
    }

    private fun JSONObject.optCaptureOptions(): IProov.Options.Capture {
        val capture = IProov.Options.Capture()
        capture.camera = optCamera(capture.camera)
        capture.faceDetector = optFaceDetector(capture.faceDetector)
        capture.maxYaw = optFloat("max_yaw", capture.maxYaw)
        capture.maxRoll = optFloat("max_roll", capture.maxRoll)
        capture.maxPitch = optFloat("max_pitch", capture.maxPitch)
        return capture
    }

    private fun JSONObject.networkOptionsFromJson(context: Context): IProov.Options.Network {
        val network = IProov.Options.Network()
        network.path = optString("path", network.path)
        network.timeoutSecs = optInt("timeout", network.timeoutSecs)
        network.certificates = optCertificates(context, network.certificates)
        return network
    }

    private fun JSONObject.optCertificates(context: Context, fallback: List<Int>): List<Int> {
        val certificates = optJSONArray("certificates") ?: return fallback
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

    private fun JSONObject.optFontResource(context: Context): Int {
        val resourceName = optString("font_resource")
        if (resourceName.isNullOrEmpty()) return -1
        val resId = context.resources.getIdentifier(resourceName, "font", context.packageName)
        return if (resId == 0) -1 else resId
    }

    private fun JSONObject.optDrawableResource(context: Context, key: String): Int {
        val resourceName = optString(key)
        if (resourceName.isNullOrEmpty()) return -1
        val resId = context.resources.getIdentifier(resourceName, "drawable", context.packageName)
        return if (resId == 0) -1 else resId
    }

    private fun JSONObject.optFilter(fallback: IProov.Filter): IProov.Filter =
            optString("filter").toFilter(fallback)

    @ColorInt
    fun JSONObject.optColor(key: String?, @ColorInt fallback: Int): Int =
        if (has(key)) try {
            Color.parseColor(optString(key))
        } catch (ex: IllegalArgumentException) {
            fallback
        } else fallback

    private fun JSONObject.optOrientation(fallback: Orientation): Orientation =
        optString("orientation").toOrientation(fallback)

    private fun JSONObject.optCamera(fallback: IProov.Camera): IProov.Camera =
        optString("camera").toCamera(fallback)

    private fun JSONObject.optFaceDetector(fallback: IProov.FaceDetector): IProov.FaceDetector =
        optString("face_detector").toFaceDetector(fallback)

    private fun JSONObject.optFloat(key: String, fallback: Float?): Float? =
        // create new Float object, so null fallback isn't converted to primitive value
        if (has(key) && !isNull(key)) java.lang.Float.valueOf(optDouble(key).toFloat()) else fallback

    private fun JSONObject.optInteger(key: String, fallback: Int?): Int? =
        // create new Integer object, so null fallback isn't converted to primitive value
        if (has(key) && !isNull(key)) Integer.valueOf(optInt(key)) else fallback

    private fun String.toFilter(fallback: IProov.Filter): IProov.Filter =
            when (this) {
                "classic" -> IProov.Filter.CLASSIC
                "shaded" -> IProov.Filter.SHADED
                "vibrant" -> IProov.Filter.VIBRANT
                else -> fallback
            }

    private fun String.toOrientation(fallback: Orientation): Orientation =
            when (this) {
                "portrait" -> Orientation.PORTRAIT
                "landscape" -> Orientation.LANDSCAPE
                "reverse_portrait" -> Orientation.REVERSE_PORTRAIT
                "reverse_landscape" -> Orientation.REVERSE_LANDSCAPE
                else -> fallback
            }

    private fun String.toCamera(fallback: IProov.Camera): IProov.Camera =
            when (this) {
                "front" -> IProov.Camera.FRONT
                "external" -> IProov.Camera.EXTERNAL
                else -> fallback
            }

    private fun String.toFaceDetector(fallback: IProov.FaceDetector): IProov.FaceDetector =
            when (this) {
                "classic" -> IProov.FaceDetector.CLASSIC
                "blazeface" -> IProov.FaceDetector.BLAZEFACE
                "mlkit", "firebase" -> IProov.FaceDetector.ML_KIT
                "auto" -> IProov.FaceDetector.AUTO
                else -> fallback
            }
}