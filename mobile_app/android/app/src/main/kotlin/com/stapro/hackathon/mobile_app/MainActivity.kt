package com.stapro.hackathon.mobile_app

import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.stapro.hackathon.mobile_app/nfc"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "getDeviceId") {
                val deviceId = getAppDeviceId()
                result.success(deviceId)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getAppDeviceId(): String {
        val prefs = getSharedPreferences("AppPrefs", Context.MODE_PRIVATE)
        var deviceId = prefs.getString("device_id", null)
        if (deviceId == null) {
            // Generate a random 8-byte ID (16 hex chars)
            deviceId = UUID.randomUUID().toString().replace("-", "").substring(0, 16).uppercase()
            prefs.edit().putString("device_id", deviceId).apply()
        }
        return deviceId!!
    }
}
