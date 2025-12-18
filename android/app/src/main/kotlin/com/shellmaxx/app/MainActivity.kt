package com.shellmaxx.app

import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Habilitar edge-to-edge para Android 15+ (API 35+)
        // Esto es necesario para aplicaciones orientadas al SDK 35 o superior.
        // WindowCompat.setDecorFitsSystemWindows es seguro llamarlo en todas las versiones,
        // pero solo tiene efecto en Android 15+ cuando targetSdk >= 35
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }
}

