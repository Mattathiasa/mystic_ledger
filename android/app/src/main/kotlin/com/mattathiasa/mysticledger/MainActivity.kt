package com.mattathiasa.mysticledger

import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val channelName = "mystic_ledger/security"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecure" -> {
                        val enabled = call.arguments as? Boolean ?: false
                        setSecure(enabled)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun setSecure(enabled: Boolean) {
        runOnUiThread {
            if (enabled) {
                // Blocks screenshots and hides the app from the task switcher.
                window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
            } else {
                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            }
        }
    }
}
