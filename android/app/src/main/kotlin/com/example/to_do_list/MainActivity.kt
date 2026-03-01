package com.example.to_do_list

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import me.carda.awesome_notifications.AwesomeNotificationsPlugin

class MainActivity : FlutterActivity() {
    private val CHANNEL = "to_do_list/battery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Create notification channel for Android O+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel("your_channel_id", "WTD", NotificationManager.IMPORTANCE_HIGH)
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }

        // Setup platform channel for battery optimization
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestBatteryExemption" -> {
                    requestBatteryExemption()
                    result.success(null)
                }
                "isBatteryExemptionEnabled" -> {
                    result.success(isBatteryExemptionEnabled())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun requestBatteryExemption() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val intent = Intent()
                val packageName = packageName
                val powerManager = getSystemService(POWER_SERVICE) as PowerManager
                
                if (!powerManager.isIgnoringBatteryOptimizations(packageName)) {
                    // Try to directly request exemption (may not work on all devices)
                    intent.action = Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                    intent.data = Uri.parse("package:$packageName")
                    startActivity(intent)
                } else {
                    // Already exempted, open settings anyway to show status
                    intent.action = Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS
                    startActivity(intent)
                }
            }
        } catch (e: Exception) {
            // Fallback to general settings
            try {
                val intent = Intent(Settings.ACTION_SETTINGS)
                startActivity(intent)
            } catch (e2: Exception) {
                // Ignore - some devices may not support this
            }
        }
    }

    private fun isBatteryExemptionEnabled(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = getSystemService(POWER_SERVICE) as PowerManager
            powerManager.isIgnoringBatteryOptimizations(packageName)
        } else {
            true
        }
    }
}
