package com.example.swasthya

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val BATTERY_CHANNEL = "com.example.swasthya/battery"
    private val SETTINGS_CHANNEL = "com.example.swasthya/settings"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Battery optimization channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestIgnoreBatteryOptimization" -> {
                    requestIgnoreBatteryOptimization()
                    result.success(true)
                }
                "isIgnoringBatteryOptimizations" -> {
                    result.success(isIgnoringBatteryOptimizations())
                }
                else -> result.notImplemented()
            }
        }

        // Settings channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SETTINGS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openAppSettings" -> {
                    openAppSettings()
                    result.success(true)
                }
                "openBatterySettings" -> {
                    openBatterySettings()
                    result.success(true)
                }
                "openAutoStartSettings" -> {
                    openAutoStartSettings()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun requestIgnoreBatteryOptimization() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = getSystemService(POWER_SERVICE) as PowerManager
            if (!powerManager.isIgnoringBatteryOptimizations(packageName)) {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                intent.data = Uri.parse("package:$packageName")
                startActivity(intent)
            }
        }
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = getSystemService(POWER_SERVICE) as PowerManager
            return powerManager.isIgnoringBatteryOptimizations(packageName)
        }
        return true
    }

    private fun openAppSettings() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
        intent.data = Uri.parse("package:$packageName")
        startActivity(intent)
    }

    private fun openBatterySettings() {
        try {
            val intent = Intent(Settings.ACTION_BATTERY_SAVER_SETTINGS)
            startActivity(intent)
        } catch (e: Exception) {
            // Fallback to app settings
            openAppSettings()
        }
    }

    private fun openAutoStartSettings() {
        // Try MIUI autostart settings
        try {
            val intent = Intent()
            intent.component = android.content.ComponentName(
                "com.miui.securitycenter",
                "com.miui.permcenter.autostart.AutoStartManagementActivity"
            )
            startActivity(intent)
            return
        } catch (e: Exception) {}

        // Try Xiaomi security app
        try {
            val intent = Intent()
            intent.component = android.content.ComponentName(
                "com.miui.securitycenter",
                "com.miui.permcenter.MainAc498ty"
            )
            startActivity(intent)
            return
        } catch (e: Exception) {}

        // Try Huawei
        try {
            val intent = Intent()
            intent.component = android.content.ComponentName(
                "com.huawei.systemmanager",
                "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"
            )
            startActivity(intent)
            return
        } catch (e: Exception) {}

        // Try Samsung
        try {
            val intent = Intent()
            intent.component = android.content.ComponentName(
                "com.samsung.android.lool",
                "com.samsung.android.sm.ui.battery.BatteryActivity"
            )
            startActivity(intent)
            return
        } catch (e: Exception) {}

        // Fallback to app settings
        openAppSettings()
    }
}
