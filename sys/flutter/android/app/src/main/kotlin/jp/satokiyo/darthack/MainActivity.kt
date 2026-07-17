package jp.satokiyo.darthack

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.view.KeyEvent
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsControllerCompat

class MainActivity : FlutterActivity() {
    private val CHANNEL = "jp.satokiyo.darthack/key_interceptor"
    private val SCREEN_MODE_CHANNEL = "jp.satokiyo.darthack/screen_mode"
    private var channel: MethodChannel? = null
    private var screenModeChannel: MethodChannel? = null

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

        screenModeChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCREEN_MODE_CHANNEL)
        screenModeChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "setScreenMode" -> {
                    val mode = call.argument<Number>("mode")?.toInt() ?: 0
                    applyScreenMode(mode)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun applyScreenMode(mode: Int) {
        val window = window ?: return
        val controller = WindowInsetsControllerCompat(window, window.decorView)
        when (mode) {
            0 -> {
                WindowCompat.setDecorFitsSystemWindows(window, true)
                controller.show(androidx.core.view.WindowInsetsCompat.Type.systemBars())
            }
            1 -> {
                WindowCompat.setDecorFitsSystemWindows(window, true)
                controller.hide(androidx.core.view.WindowInsetsCompat.Type.statusBars())
            }
            else -> {
                WindowCompat.setDecorFitsSystemWindows(window, true)
                controller.show(androidx.core.view.WindowInsetsCompat.Type.systemBars())
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

    override fun onDestroy() {
        super.onDestroy()
        android.os.Process.killProcess(android.os.Process.myPid())
    }
}
