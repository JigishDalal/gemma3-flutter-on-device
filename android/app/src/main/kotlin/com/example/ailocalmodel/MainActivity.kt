package com.example.ailocalmodel

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Register the device action platform channel handler
        DeviceActionHandler(applicationContext, flutterEngine)
    }
}
