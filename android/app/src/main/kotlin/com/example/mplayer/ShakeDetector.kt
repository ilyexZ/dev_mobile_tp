package com.example.mplayer

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import kotlin.math.sqrt

/**
 * Detects shake gestures using the device accelerometer.
 *
 * Usage:
 *   val detector = ShakeDetector(context) { /* on shake */ }
 *   detector.start()   // in onResume
 *   detector.stop()    // in onPause
 */
class ShakeDetector(
    context: Context,
    private val onShake: () -> Unit
) : SensorEventListener {

    companion object {
        // Minimum acceleration (m/s²) above gravity to count as a shake.
        // 12 is firm enough to ignore walking/jostling, easy enough to trigger intentionally.
        private const val SHAKE_THRESHOLD = 12f

        // Minimum ms between two shake callbacks (prevents double-firing).
        private const val DEBOUNCE_MS = 600L
    }

    private val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val accelerometer  = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

    private var lastShakeTime = 0L

    fun start() {
        accelerometer?.let {
            sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_UI)
        }
    }

    fun stop() {
        sensorManager.unregisterListener(this)
    }

    override fun onSensorChanged(event: SensorEvent) {
        val x = event.values[0]
        val y = event.values[1]
        val z = event.values[2]

        // Net acceleration with gravity removed
        val net = sqrt(x * x + y * y + z * z) - SensorManager.GRAVITY_EARTH

        if (net > SHAKE_THRESHOLD) {
            val now = System.currentTimeMillis()
            if (now - lastShakeTime > DEBOUNCE_MS) {
                lastShakeTime = now
                onShake()
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit
}