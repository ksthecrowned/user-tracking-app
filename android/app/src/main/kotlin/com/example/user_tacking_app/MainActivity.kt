package com.example.user_tacking_app

import io.flutter.embedding.android.FlutterActivity
import com.yandex.mapkit.MapKitFactory
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // Set API key before any other MapKit interactions
        MapKitFactory.setApiKey("9abea6a4-742d-4d95-bf3a-32fb94eee4e4")
        
        // Initialize MapKit
        MapKitFactory.initialize(this)
        
        // Register all plugins including Yandex MapKit
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        super.configureFlutterEngine(flutterEngine)
    }

    override fun onStart() {
        super.onStart()
        MapKitFactory.getInstance().onStart()
    }

    override fun onStop() {
        MapKitFactory.getInstance().onStop()
        super.onStop()
    }
}