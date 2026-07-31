package com.jarvis.wlan

import android.content.Context
import com.jarvis.wlan.data.SettingsRepository
import com.jarvis.wlan.net.JarvisClient
import com.jarvis.wlan.net.ServerDiscovery
import com.jarvis.wlan.util.NetworkStatus

/**
 * Handverdrahtete Abhängigkeiten. Für den Umfang dieser App wäre ein
 * DI-Framework mehr Zeremonie als Nutzen.
 */
object ServiceLocator {

    @Volatile
    private var initialized = false

    lateinit var settingsRepository: SettingsRepository
        private set
    lateinit var jarvisClient: JarvisClient
        private set
    lateinit var networkStatus: NetworkStatus
        private set
    lateinit var serverDiscovery: ServerDiscovery
        private set

    @Synchronized
    fun init(context: Context) {
        if (initialized) return
        val app = context.applicationContext
        settingsRepository = SettingsRepository(app)
        jarvisClient = JarvisClient()
        networkStatus = NetworkStatus(app)
        serverDiscovery = ServerDiscovery(app, networkStatus)
        initialized = true
    }
}
