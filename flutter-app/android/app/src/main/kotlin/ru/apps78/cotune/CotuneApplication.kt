package ru.apps78.cotune

import android.app.Application
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

class CotuneApplication : Application() {
    private lateinit var flutterEngine: FlutterEngine

    override fun onCreate() {
        super.onCreate()

        // Initialize Flutter engine
        flutterEngine = FlutterEngine(this)
        
        // Register custom plugins
        flutterEngine.plugins.add(CotuneNodePlugin())
        
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )

        // Cache the engine
        FlutterEngineCache.getInstance().put("cotune_engine", flutterEngine)
    }
}
