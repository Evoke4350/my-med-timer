package com.nateb.mymedtimer.data.haptic

import android.annotation.SuppressLint
import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager

object HapticService {

    enum class Pattern {
        NOTIFICATION,  // gentle single pulse
        WARNING,       // urgent double-tap
        SUCCESS,       // confirmed action feedback
        ESCALATING     // repeated heavy buzz
    }

    @SuppressLint("MissingPermission") // VIBRATE permission declared in app manifest
    fun play(context: Context, pattern: Pattern) {
        val vibrator = getVibrator(context) ?: return

        val effect = when (pattern) {
            Pattern.NOTIFICATION -> VibrationEffect.createOneShot(100, VibrationEffect.DEFAULT_AMPLITUDE)
            Pattern.WARNING -> VibrationEffect.createWaveform(
                longArrayOf(0, 80, 60, 80),
                intArrayOf(0, 200, 0, 200),
                -1 // no repeat
            )
            Pattern.SUCCESS -> VibrationEffect.createOneShot(50, 120)
            Pattern.ESCALATING -> VibrationEffect.createWaveform(
                longArrayOf(0, 150, 80, 150, 80, 300),
                intArrayOf(0, 180, 0, 220, 0, 255),
                -1
            )
        }

        vibrator.vibrate(effect)
    }

    fun playForAlertStyle(context: Context, alertStyle: String) {
        when (alertStyle) {
            "urgent" -> play(context, Pattern.WARNING)
            "escalating" -> play(context, Pattern.ESCALATING)
            else -> play(context, Pattern.NOTIFICATION)
        }
    }

    private fun getVibrator(context: Context): Vibrator? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = context.getSystemService(VibratorManager::class.java)
            manager?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }
}
