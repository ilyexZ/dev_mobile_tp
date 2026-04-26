package com.example.mplayer

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        /** Lets MusicService call back into MainActivity when notification buttons are tapped. */
        var instance: MainActivity? = null

        private const val METHOD_CHANNEL = "mplayer/audio"
        private const val EVENT_CHANNEL = "mplayer/audio_events"
    }

    // ── Service binding ───────────────────────────────────────────────────────
    private var musicService: MusicService? = null
    private var isBound = false

    /**
     * If a play command arrives before [onServiceConnected] fires (race on first launch), we park
     * it here and invoke it the moment the service is ready.
     */
    private var pendingAction: (() -> Unit)? = null

    private val serviceConnection =
            object : ServiceConnection {
                override fun onServiceConnected(name: ComponentName?, binder: IBinder?) {
                    musicService = (binder as MusicService.LocalBinder).getService()
                    isBound = true

                    // ── Wire service callbacks → Flutter events ───────────────────────
                    musicService?.onCompletion = { sendEvent(mapOf("type" to "completion")) }
                    musicService?.onStateChanged = { playing ->
                        sendEvent(mapOf("type" to "stateChanged", "isPlaying" to playing))
                    }
                    // Notification Prev / Next buttons tell Flutter to handle navigation
                    musicService?.onPrev = { sendEvent(mapOf("type" to "prev")) }
                    musicService?.onNext = { sendEvent(mapOf("type" to "next")) }

                    // Execute any play command that arrived before binding completed
                    pendingAction?.invoke()
                    pendingAction = null
                }
                override fun onServiceDisconnected(name: ComponentName?) {
                    isBound = false
                }
            }

    // ── Position polling (Native → Flutter every 500 ms) ─────────────────────
    private var eventSink: EventChannel.EventSink? = null
    private val handler = Handler(Looper.getMainLooper())
    private val positionRunnable =
            object : Runnable {
                override fun run() {
                    if (eventSink != null) {
                        val pos = musicService?.getCurrentPosition() ?: 0
                        val dur = musicService?.getDuration() ?: 0
                        sendEvent(mapOf("type" to "position", "position" to pos, "duration" to dur))
                    }
                    handler.postDelayed(this, 500)
                }
            }

    // ── Flutter engine setup ──────────────────────────────────────────────────
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        instance = this

        // ── IMPORTANT: startService() BEFORE bindService() ────────────────────
        // startService() puts the service into the proper "started" lifecycle:
        //   onCreate() → onStartCommand() runs first.
        // This is required for startForeground() to work on API 31+.
        // Calling startForeground() from a bind-only service (BIND_AUTO_CREATE
        // without a prior startService) throws ForegroundServiceStartNotAllowedException
        // on Android 12+, which silently breaks the service and is the root cause
        // of the first-launch play button doing nothing.
        // bindService() still gives us the IBinder for direct calls and triggers
        // onServiceConnected() once ready — the pendingAction handles any play
        // command that arrives before that callback fires.
        val serviceIntent = Intent(this, MusicService::class.java)
        startService(serviceIntent)
        bindService(serviceIntent, serviceConnection, Context.BIND_AUTO_CREATE)

        // ── MethodChannel: Flutter → Native ───────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
                .setMethodCallHandler { call, result ->
                    when (call.method) {
                        "playAsset" -> {
                            val path = call.argument<String>("path") ?: ""
                            val title = call.argument<String>("title") ?: ""
                            val artist = call.argument<String>("artist") ?: ""
                            if (isBound) {
                                musicService?.playAsset(path, title, artist)
                            } else {
                                pendingAction = { musicService?.playAsset(path, title, artist) }
                            }
                            result.success(null)
                        }
                        "playFile" -> {
                            val path = call.argument<String>("path") ?: ""
                            val title = call.argument<String>("title") ?: ""
                            val artist = call.argument<String>("artist") ?: ""
                            if (isBound) {
                                musicService?.playFile(path, title, artist)
                            } else {
                                pendingAction = { musicService?.playFile(path, title, artist) }
                            }
                            result.success(null)
                        }
                        "pause" -> {
                            musicService?.pause()
                            result.success(null)
                        }
                        "resume" -> {
                            musicService?.resume()
                            result.success(null)
                        }
                        "stop" -> {
                            musicService?.stop()
                            result.success(null)
                        }
                        "seek" -> {
                            val ms = call.argument<Int>("ms") ?: 0
                            musicService?.seek(ms)
                            result.success(null)
                        }
                        "isPlaying" -> result.success(musicService?.isPlaying() ?: false)
                        "getPosition" -> result.success(musicService?.getCurrentPosition() ?: 0)
                        "getDuration" -> result.success(musicService?.getDuration() ?: 0)
                        else -> result.notImplemented()
                    }
                }

        // ── EventChannel: Native → Flutter ────────────────────────────────────
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
                .setStreamHandler(
                        object : EventChannel.StreamHandler {
                            override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                                eventSink = sink
                                handler.post(positionRunnable)
                            }
                            override fun onCancel(arguments: Any?) {
                                eventSink = null
                                handler.removeCallbacks(positionRunnable)
                            }
                        }
                )
    }

    /**
     * Called by MusicService when the notification Pause/Resume button is tapped, so Flutter can
     * sync its own UI state.
     */
    fun onNativePlayPauseToggled() {
        val playing = musicService?.isPlaying() ?: false
        sendEvent(mapOf("type" to "stateChanged", "isPlaying" to playing))
    }

    // ── Helpers ───────────────────────────────────────────────────────────────
    private fun sendEvent(data: Any) {
        runOnUiThread { eventSink?.success(data) }
    }

    // ── Cleanup ───────────────────────────────────────────────────────────────
    override fun onDestroy() {
        handler.removeCallbacks(positionRunnable)
        if (isBound) {
            unbindService(serviceConnection)
            isBound = false
        }
        instance = null
        super.onDestroy()
    }
}
