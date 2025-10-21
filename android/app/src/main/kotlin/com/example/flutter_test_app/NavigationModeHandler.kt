// NavigationModeHandler.kt
package com.synxrhyme.hazelnut

import android.os.Build
import android.view.ViewConfiguration
import android.view.WindowInsets
import android.app.Activity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result

class NavigationModeHandler(private val activity: Activity) {

    fun handle(call: MethodCall, result: Result) {
        if (call.method == "getNavigationMode") {
            result.success(getNavigationMode())
        } else {
            result.notImplemented()
        }
    }

    private fun getNavigationMode(): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val insets = activity.window.decorView.rootWindowInsets
            val visible = insets?.isVisible(WindowInsets.Type.navigationBars()) ?: true
            if (visible) "buttons" else "gestures"
        } else {
            if (ViewConfiguration.get(activity).hasPermanentMenuKey()) "buttons" else "gestures"
        }
    }
}