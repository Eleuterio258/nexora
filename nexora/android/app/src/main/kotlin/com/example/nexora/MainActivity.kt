package com.example.nexora

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val methodChannelName = "nexora/face_detector"
    private val eventChannelName = "nexora/face_detector/results"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
        val handler = MediaPipeFaceDetectorHandler(applicationContext, methodChannel)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
            .setStreamHandler(handler)
    }
}
