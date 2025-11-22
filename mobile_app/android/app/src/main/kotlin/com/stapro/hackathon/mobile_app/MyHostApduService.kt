package com.stapro.hackathon.mobile_app

import android.content.Context
import android.nfc.cardemulation.HostApduService
import android.os.Bundle
import android.util.Log
import java.util.UUID

class MyHostApduService : HostApduService() {

    companion object {
        private const val TAG = "MyHostApduService"
        private const val AID = "F0010203040506"
        private const val SELECT_APDU_HEADER = "00A40400"
        private const val READ_ID_CMD = "B0000000" // Custom command to read ID
        private const val STATUS_SUCCESS = "9000"
        private const val STATUS_FAILED = "6F00"
    }

    override fun processCommandApdu(commandApdu: ByteArray, extras: Bundle?): ByteArray {
        val command = toHex(commandApdu)
        Log.d(TAG, "Received APDU: $command")

        if (command.startsWith(SELECT_APDU_HEADER)) {
            Log.d(TAG, "SELECT AID received")
            return hexStringToByteArray(STATUS_SUCCESS)
        } else if (command.startsWith(READ_ID_CMD)) {
            Log.d(TAG, "READ ID received")
            val deviceId = getAppDeviceId()
            val response = deviceId + STATUS_SUCCESS
            Log.d(TAG, "Responding with Device ID: $deviceId")
            return hexStringToByteArray(response)
        }

        return hexStringToByteArray(STATUS_FAILED)
    }

    override fun onDeactivated(reason: Int) {
        Log.d(TAG, "Deactivated: $reason")
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

    private fun toHex(bytes: ByteArray): String {
        val sb = StringBuilder()
        for (b in bytes) {
            sb.append(String.format("%02X", b))
        }
        return sb.toString()
    }

    private fun hexStringToByteArray(s: String): ByteArray {
        val len = s.length
        val data = ByteArray(len / 2)
        var i = 0
        while (i < len) {
            data[i / 2] = ((Character.digit(s[i], 16) shl 4) + Character.digit(s[i + 1], 16)).toByte()
            i += 2
        }
        return data
    }
}
