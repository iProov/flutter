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
        options.apply {
            ui = json.optJSONObject("ui")?.optUIOptions(context) ?: ui
            capture = json.optJSONObject("capture")?.optCaptureOptions() ?: capture
            network = json.optJSONObject("network")?.networkOptionsFromJson(context) ?: network
            return this
        }
    }

    private fun JSONObject.optUIOptions(context: Context): IProov.Options.UI =
        IProov.Options.UI().apply {
            autoStartDisabled = optBoolean("auto_start_disabled", autoStartDisabled)
            filter = optFilter(filter)
            lineColor = optColor("line_color", lineColor)
            backgroundColor = optColor("background_color", backgroundColor)
            loadingTintColor = optColor("loading_tint_color", loadingTintColor)
            notReadyTintColor = optColor("not_ready_tint_color", notReadyTintColor)
            livenessTintColor = optColor("liveness_tint_color", livenessTintColor)
            title = optString("title", title)
            fontPath = optString("font_path", fontPath)
            fontResource = optFontResource(context)
            scanLineDisabled = optBoolean("scan_line_disabled", scanLineDisabled)
            enableScreenshots = optBoolean("enable_screenshots", enableScreenshots)
            orientation = optOrientation(orientation)
            logoImageResource = optDrawableResource(context, "logo_image_resource")
            activityCompatibilityRequestCode = optInteger("activity_compatibility_request_code", activityCompatibilityRequestCode)
        }

    private fun JSONObject.optCaptureOptions(): IProov.Options.Capture =
        IProov.Options.Capture().apply {
            camera = optCamera(camera)
            faceDetector = optFaceDetector(faceDetector)
            maxYaw = optFloat("max_yaw", maxYaw)
            maxRoll = optFloat("max_roll", maxRoll)
            maxPitch = optFloat("max_pitch", maxPitch)
        }

    private fun JSONObject.networkOptionsFromJson(context: Context): IProov.Options.Network =
        IProov.Options.Network().apply {
            path = optString("path", path)
            timeoutSecs = optInt("timeout", timeoutSecs)
            certificates = optCertificates(context, certificates)
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