package com.chonggao.pomodo

import android.media.MediaPlayer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.pomodo.app/audio"
    private var mediaPlayer: MediaPlayer? = null
    private var currentPath: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "play" -> {
                    val path = call.argument<String>("path")
                    val volume = (call.argument<Double>("volume") ?: 0.65).toFloat()
                    if (path != null) {
                        playAudio(path, volume)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Path is null", null)
                    }
                }
                "stop" -> {
                    stopAudio()
                    result.success(true)
                }
                "pause" -> {
                    mediaPlayer?.let {
                        if (it.isPlaying) {
                            it.pause()
                        }
                    }
                    result.success(true)
                }
                "resume" -> {
                    mediaPlayer?.let {
                        if (!it.isPlaying) {
                            it.start()
                        }
                    }
                    result.success(true)
                }
                "setVolume" -> {
                    val volume = (call.argument<Double>("volume") ?: 0.65).toFloat()
                    mediaPlayer?.setVolume(volume, volume)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun playAudio(path: String, volume: Float) {
        try {
            if (mediaPlayer != null && currentPath == path && mediaPlayer!!.isPlaying) {
                mediaPlayer?.setVolume(volume, volume)
                return
            }

            stopAudio()

            val file = File(path)
            if (!file.exists()) {
                return
            }

            mediaPlayer = MediaPlayer().apply {
                setDataSource(path)
                isLooping = true
                setVolume(volume, volume)
                prepare()
                start()
            }
            currentPath = path
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun stopAudio() {
        try {
            mediaPlayer?.let {
                if (it.isPlaying) {
                    it.stop()
                }
                it.release()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            mediaPlayer = null
            currentPath = null
        }
    }

    override fun onDestroy() {
        stopAudio()
        super.onDestroy()
    }
}
