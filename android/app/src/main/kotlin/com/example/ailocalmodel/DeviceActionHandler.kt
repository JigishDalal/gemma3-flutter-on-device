package com.example.ailocalmodel

import android.content.Context
import android.content.Intent
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.net.Uri
import android.provider.CalendarContract
import android.provider.ContactsContract
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

private const val TAG = "DeviceActionHandler"
private const val CHANNEL = "com.ailocalmodel/device_actions"

/**
 * Handles platform channel calls from Flutter to execute device actions:
 * flashlight, contacts, email, maps, WiFi settings, calendar.
 */
class DeviceActionHandler(
    private val context: Context,
    flutterEngine: FlutterEngine
) : MethodChannel.MethodCallHandler {

    init {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, CHANNEL
        ).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "toggleFlashlight" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    setFlashlight(enabled)
                    result.success(null)
                }
                "createContact" -> {
                    val name = call.argument<String>("name") ?: ""
                    val phone = call.argument<String>("phone") ?: ""
                    val email = call.argument<String>("email") ?: ""
                    openCreateContact(name, phone, email)
                    result.success(null)
                }
                "sendEmail" -> {
                    val to = call.argument<String>("to") ?: ""
                    val subject = call.argument<String>("subject") ?: ""
                    val body = call.argument<String>("body") ?: ""
                    openSendEmail(to, subject, body)
                    result.success(null)
                }
                "showLocationOnMap" -> {
                    val location = call.argument<String>("location") ?: ""
                    openMap(location)
                    result.success(null)
                }
                "openWifiSettings" -> {
                    openWifi()
                    result.success(null)
                }
                "createCalendarEvent" -> {
                    val title = call.argument<String>("title") ?: ""
                    val startTime = call.argument<String>("start_time") ?: ""
                    val endTime = call.argument<String>("end_time") ?: ""
                    openCreateCalendarEvent(title, startTime, endTime)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error executing ${call.method}", e)
            result.error("ACTION_ERROR", e.message, null)
        }
    }

    // ── Flashlight ────────────────────────────────────────────────────────

    private fun setFlashlight(enabled: Boolean) {
        val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
        val cameraId = cameraManager.cameraIdList.firstOrNull { id ->
            cameraManager.getCameraCharacteristics(id)
                .get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
        }
        if (cameraId != null) {
            cameraManager.setTorchMode(cameraId, enabled)
            Log.d(TAG, "Flashlight ${if (enabled) "ON" else "OFF"}")
        } else {
            throw Exception("No camera with flashlight found")
        }
    }

    // ── Contacts ──────────────────────────────────────────────────────────

    private fun openCreateContact(name: String, phone: String, email: String) {
        val intent = Intent(ContactsContract.Intents.Insert.ACTION).apply {
            type = ContactsContract.RawContacts.CONTENT_TYPE
            putExtra(ContactsContract.Intents.Insert.NAME, name)
            if (phone.isNotEmpty()) {
                putExtra(ContactsContract.Intents.Insert.PHONE, phone)
            }
            if (email.isNotEmpty()) {
                putExtra(ContactsContract.Intents.Insert.EMAIL, email)
            }
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }

    // ── Email ─────────────────────────────────────────────────────────────

    private fun openSendEmail(to: String, subject: String, body: String) {
        val uri = Uri.parse("mailto:$to")
        val intent = Intent(Intent.ACTION_SENDTO, uri).apply {
            putExtra(Intent.EXTRA_SUBJECT, subject)
            putExtra(Intent.EXTRA_TEXT, body)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }

    // ── Maps ──────────────────────────────────────────────────────────────

    private fun openMap(location: String) {
        val encodedLocation = Uri.encode(location)
        val uri = Uri.parse("geo:0,0?q=$encodedLocation")
        val intent = Intent(Intent.ACTION_VIEW, uri).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }

    // ── WiFi Settings ─────────────────────────────────────────────────────

    private fun openWifi() {
        val intent = Intent(Settings.ACTION_WIFI_SETTINGS).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }

    // ── Calendar ──────────────────────────────────────────────────────────

    private fun openCreateCalendarEvent(title: String, startTime: String, endTime: String) {
        val intent = Intent(Intent.ACTION_INSERT).apply {
            data = CalendarContract.Events.CONTENT_URI
            putExtra(CalendarContract.Events.TITLE, title)
            // Parse ISO 8601 times if provided
            if (startTime.isNotEmpty()) {
                try {
                    val startMillis = java.time.Instant.parse(startTime).toEpochMilli()
                    putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, startMillis)
                } catch (_: Exception) {
                    Log.w(TAG, "Could not parse start_time: $startTime")
                }
            }
            if (endTime.isNotEmpty()) {
                try {
                    val endMillis = java.time.Instant.parse(endTime).toEpochMilli()
                    putExtra(CalendarContract.EXTRA_EVENT_END_TIME, endMillis)
                } catch (_: Exception) {
                    Log.w(TAG, "Could not parse end_time: $endTime")
                }
            }
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }
}
