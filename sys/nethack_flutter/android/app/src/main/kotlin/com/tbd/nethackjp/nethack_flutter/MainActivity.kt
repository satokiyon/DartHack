package com.tbd.nethackjp.nethack_flutter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.view.KeyEvent

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.tbd.nethackjp/key_interceptor"
    private var channel: MethodChannel? = null

    private var interceptVolumeUp = false
    private var interceptVolumeDown = false
    private var interceptBack = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "updateInterceptorSettings" -> {
                    interceptVolumeUp = call.argument<Boolean>("volumeUp") ?: false
                    interceptVolumeDown = call.argument<Boolean>("volumeDown") ?: false
                    interceptBack = call.argument<Boolean>("back") ?: false
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        val keyCode = event.keyCode
        val action = event.action

        if (action == KeyEvent.ACTION_DOWN) {
            when (keyCode) {
                KeyEvent.KEYCODE_VOLUME_UP -> {
                    if (interceptVolumeUp) {
                        channel?.invokeMethod("onKeyEvent", mapOf("key" to "volume_up"))
                        return true
                    }
                }
                KeyEvent.KEYCODE_VOLUME_DOWN -> {
                    if (interceptVolumeDown) {
                        channel?.invokeMethod("onKeyEvent", mapOf("key" to "volume_down"))
                        return true
                    }
                }
                KeyEvent.KEYCODE_BACK -> {
                    if (interceptBack) {
                        channel?.invokeMethod("onKeyEvent", mapOf("key" to "back"))
                        return true
                    }
                }
            }
        } else if (action == KeyEvent.ACTION_UP) {
            when (keyCode) {
                KeyEvent.KEYCODE_VOLUME_UP -> {
                    if (interceptVolumeUp) return true
                }
                KeyEvent.KEYCODE_VOLUME_DOWN -> {
                    if (interceptVolumeDown) return true
                }
                KeyEvent.KEYCODE_BACK -> {
                    if (interceptBack) return true
                }
            }
        }

        return super.dispatchKeyEvent(event)
    }
}
