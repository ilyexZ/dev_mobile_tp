package com.example.mplayer

import android.app.*
import android.content.Context
import android.content.Intent
import android.media.MediaPlayer
import android.os.Binder
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

// import androidx.media.app.NotificationCompat.MediaStyle

class MusicService : Service() {

    companion object {
        const val ACTION_PLAY_PAUSE = "PLAY_PAUSE"
        const val ACTION_PREV = "PREV" // ← new
        const val ACTION_NEXT = "NEXT" // ← new
        const val CHANNEL_ID = "mplayer_channel"
        const val NOTIF_ID = 1
    }

    // ── State ─────────────────────────────────────────────────────────────────
    private var mediaPlayer: MediaPlayer? = null
    private var currentTitle = "mPlayer"
    private var isForeground = false

    /** Called when playback finishes naturally (to trigger next song in Flutter). */
    var onCompletion: (() -> Unit)? = null

    /** Called when play/pause state changes so Flutter can sync its UI. */
    var onStateChanged: ((Boolean) -> Unit)? = null

    /** Called when the notification Previous button is tapped. */
    var onPrev: (() -> Unit)? = null // ← new

    /** Called when the notification Next button is tapped. */
    var onNext: (() -> Unit)? = null // ← new

    // ── Binder ────────────────────────────────────────────────────────────────
    private val binder = LocalBinder()
    inner class LocalBinder : Binder() {
        fun getService(): MusicService = this@MusicService
    }
    override fun onBind(intent: Intent): IBinder = binder

    // ── Lifecycle ─────────────────────────────────────────────────────────────
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        // NOTE: startForeground() is NOT called here intentionally.
        //
        // The service is brought into the "started" state via startService() in
        // MainActivity.configureFlutterEngine(). startForeground() is only called
        // from playAsset() / playFile() once we have real content to display.
        //
        // Calling startForeground() from onCreate() on a bind-only service
        // (BIND_AUTO_CREATE without a prior startService) throws
        // ForegroundServiceStartNotAllowedException on Android 12+ and breaks
        // the service silently — that was the root cause of the first-launch bug.
    }

    /**
     * Handles notification button taps (play/pause, prev, next). MainActivity's startService() on
     * init also lands here with a null action — that's fine.
     */
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_PLAY_PAUSE -> {
                if (isPlaying()) pause() else resume()
                MainActivity.instance?.onNativePlayPauseToggled()
            }
            ACTION_PREV -> onPrev?.invoke() // ← new: delegate to Flutter
            ACTION_NEXT -> onNext?.invoke() // ← new: delegate to Flutter
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        mediaPlayer?.release()
        mediaPlayer = null
        super.onDestroy()
    }
    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        releasePlayer()
        stopForeground(true)
        stopSelf()
    }

    // ── Playback API ──────────────────────────────────────────────────────────

    fun playAsset(flutterAssetPath: String, title: String, artist: String) {
        currentTitle = title
        try {
            releasePlayer()
            val afd = assets.openFd("flutter_assets/assets/$flutterAssetPath")
            mediaPlayer =
                    MediaPlayer().apply {
                        setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                        afd.close()
                        prepare()
                        start()
                        setOnCompletionListener { onCompletion?.invoke() }
                    }
            showForegroundNotification()
            onStateChanged?.invoke(true)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /** Play an absolute file path picked from device storage. */
    fun playFile(filePath: String, title: String, artist: String) {
        currentTitle = title
        try {
            releasePlayer()
            mediaPlayer =
                    MediaPlayer().apply {
                        setDataSource(filePath)
                        prepare()
                        start()
                        setOnCompletionListener { onCompletion?.invoke() }
                    }
            showForegroundNotification()
            onStateChanged?.invoke(true)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun pause() {
        mediaPlayer?.pause()
        updateNotification()
        onStateChanged?.invoke(false)
    }

    fun resume() {
        mediaPlayer?.start()
        updateNotification()
        onStateChanged?.invoke(true)
    }

    fun stop() {
        releasePlayer()
        currentTitle = "mPlayer"
        if (isForeground) updateNotification()
        onStateChanged?.invoke(false)
    }

    fun seek(ms: Int) {
        mediaPlayer?.seekTo(ms)
    }

    fun isPlaying(): Boolean = mediaPlayer?.isPlaying ?: false
    fun getCurrentPosition(): Int = mediaPlayer?.currentPosition ?: 0
    fun getDuration(): Int = mediaPlayer?.duration ?: 0

    // ── Notification ──────────────────────────────────────────────────────────

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel =
                    NotificationChannel(CHANNEL_ID, "mPlayer", NotificationManager.IMPORTANCE_LOW)
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }

    private fun showForegroundNotification() {
        val notif = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                    NOTIF_ID,
                    notif,
                    android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
            )
        } else {
            startForeground(NOTIF_ID, notif)
        }
        isForeground = true
    }

    private fun updateNotification() {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIF_ID, buildNotification())
    }

    private fun buildNotification(): Notification {
        // ── Tap notification → open app ───────────────────────────────────────
        val openIntent =
                Intent(this, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
                }
        val pendingOpen =
                PendingIntent.getActivity(this, 0, openIntent, PendingIntent.FLAG_IMMUTABLE)

        // ── Action: Previous ──────────────────────────────────────────────────
        val pendingPrev =
                PendingIntent.getService(
                        this,
                        1,
                        Intent(this, MusicService::class.java).apply { action = ACTION_PREV },
                        PendingIntent.FLAG_IMMUTABLE
                )

        // ── Action: Play / Pause ──────────────────────────────────────────────
        val pendingPP =
                PendingIntent.getService(
                        this,
                        2,
                        Intent(this, MusicService::class.java).apply { action = ACTION_PLAY_PAUSE },
                        PendingIntent.FLAG_IMMUTABLE
                )
        val ppIcon =
                if (isPlaying()) android.R.drawable.ic_media_pause
                else android.R.drawable.ic_media_play
        val ppLabel = if (isPlaying()) "Pause" else "Resume"

        // ── Action: Next ──────────────────────────────────────────────────────
        val pendingNext =
                PendingIntent.getService(
                        this,
                        3,
                        Intent(this, MusicService::class.java).apply { action = ACTION_NEXT },
                        PendingIntent.FLAG_IMMUTABLE
                )

        // ── Build notification with MediaStyle ────────────────────────────────
        // setShowActionsInCompactView(0, 1, 2) → all 3 buttons visible without
        // the user having to expand the notification.
        return NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle(currentTitle)
                .setSmallIcon(android.R.drawable.ic_media_play)
                .setContentIntent(pendingOpen)
                .addAction(android.R.drawable.ic_media_previous, "Previous", pendingPrev) // index 0
                .addAction(ppIcon, ppLabel, pendingPP) // index 1
                .addAction(android.R.drawable.ic_media_next, "Next", pendingNext) // index 2
                .setStyle(
                        androidx.media.app.NotificationCompat.MediaStyle()
                                .setShowActionsInCompactView(0, 1, 2)
                )
                .setOngoing(true)
                .build()
    }

    // ── Helpers ───────────────────────────────────────────────────────────────
    private fun releasePlayer() {
        mediaPlayer?.stop()
        mediaPlayer?.release()
        mediaPlayer = null
    }
}