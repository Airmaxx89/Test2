package com.jarvis.wlan

import android.app.Application

class JarvisApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        ServiceLocator.init(this)
    }
}
