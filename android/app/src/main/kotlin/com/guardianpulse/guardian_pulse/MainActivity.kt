package com.guardianpulse.guardian_pulse

import android.telephony.SmsManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.guardianpulse/sms"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "sendSMS") {
                val phone = call.argument<String>("phone")
                val message = call.argument<String>("message")
                if (phone != null && message != null) {
                    try {
                        val smsManager: SmsManager = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                            context.getSystemService(SmsManager::class.java)
                        } else {
                            @Suppress("DEPRECATION")
                            SmsManager.getDefault()
                        }

                        // Clean phone number: remove all spaces, dashes, parentheses
                        val cleanPhone = phone.replace(Regex("[\\s\\-()]+"), "")

                        // Use multipart to handle messages longer than 160 chars
                        val parts = smsManager.divideMessage(message)
                        if (parts.size == 1) {
                            smsManager.sendTextMessage(cleanPhone, null, message, null, null)
                        } else {
                            smsManager.sendMultipartTextMessage(cleanPhone, null, parts, null, null)
                        }
                        result.success("SMS Sent to $cleanPhone")
                    } catch (e: Exception) {
                        result.error("SMS_FAILED", "Failed: ${e.message}", null)
                    }
                } else {
                    result.error("INVALID_ARGS", "Phone or message was null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
