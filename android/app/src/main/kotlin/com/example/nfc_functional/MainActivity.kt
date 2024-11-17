package com.example.nfc_functional

import android.content.Intent
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.tech.Ndef
import android.os.Bundle
import android.telephony.SmsManager
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

class MainActivity : FlutterActivity() {
    private val SMS_CHANNEL = "com.example.sms"
    private val NFC_CHANNEL = "com.example.nfc"

    private var nfcMethodChannel: MethodChannel? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Set up MethodChannel for SMS functionality
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sendSms" -> {
                        val phoneNumber = call.argument<String>("phoneNumber")
                        val message = call.argument<String>("message")
                        if (phoneNumber != null && message != null) {
                            sendSms(phoneNumber, message)
                            result.success("SMS sent")
                        } else {
                            result.error("INVALID_ARGUMENTS", "Phone number or message is missing", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // Set up MethodChannel for NFC functionality
        nfcMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NFC_CHANNEL)
        nfcMethodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "readNfc" -> {
                    // Handle NFC reading (if needed)
                    result.success("NFC read channel set up")
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleNfcIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleNfcIntent(intent)
    }

    private fun handleNfcIntent(intent: Intent?) {
        if (intent != null && NfcAdapter.ACTION_TECH_DISCOVERED == intent.action) {
            val tag: Tag? = intent.getParcelableExtra(NfcAdapter.EXTRA_TAG)
            tag?.let {
                // Get tag ID in hexadecimal format
                val tagId = it.id.joinToString(separator = "") { byte -> String.format("%02X", byte) }
                Log.d("NFC", "Tag ID: $tagId")

                // Send NFC tag ID to Flutter
                nfcMethodChannel?.invokeMethod("onNfcDetected", tagId)
            }
        }
    }

    private fun sendSms(phoneNumber: String, message: String) {
        val smsManager = SmsManager.getDefault()
        smsManager.sendTextMessage(phoneNumber, null, message, null, null)
    }
}
