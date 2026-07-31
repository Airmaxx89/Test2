package com.jarvis.wlan.data

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "jarvis_settings")

class SettingsRepository(private val context: Context) {

    val settings: Flow<ServerSettings> = context.dataStore.data.map { prefs ->
        ServerSettings(
            scheme = prefs[Keys.SCHEME] ?: ServerSettings.DEFAULT_SCHEME,
            host = prefs[Keys.HOST].orEmpty(),
            port = prefs[Keys.PORT] ?: ServerSettings.DEFAULT_PORT,
            apiMode = ApiMode.fromName(prefs[Keys.API_MODE]),
            model = prefs[Keys.MODEL] ?: "jarvis-local",
            apiKey = prefs[Keys.API_KEY].orEmpty(),
            streaming = prefs[Keys.STREAMING] ?: true,
            speakReplies = prefs[Keys.SPEAK] ?: false,
            wifiOnly = prefs[Keys.WIFI_ONLY] ?: true,
            timeoutSeconds = prefs[Keys.TIMEOUT] ?: ServerSettings.DEFAULT_TIMEOUT_SECONDS,
            systemPrompt = prefs[Keys.SYSTEM_PROMPT].orEmpty(),
        )
    }

    suspend fun save(settings: ServerSettings) {
        context.dataStore.edit { prefs ->
            prefs[Keys.SCHEME] = settings.scheme
            prefs[Keys.HOST] = settings.host.trim()
            prefs[Keys.PORT] = settings.port
            prefs[Keys.API_MODE] = settings.apiMode.name
            prefs[Keys.MODEL] = settings.model.trim()
            prefs[Keys.API_KEY] = settings.apiKey.trim()
            prefs[Keys.STREAMING] = settings.streaming
            prefs[Keys.SPEAK] = settings.speakReplies
            prefs[Keys.WIFI_ONLY] = settings.wifiOnly
            prefs[Keys.TIMEOUT] = settings.timeoutSeconds
            prefs[Keys.SYSTEM_PROMPT] = settings.systemPrompt
        }
    }

    suspend fun setSpeakReplies(enabled: Boolean) {
        context.dataStore.edit { prefs -> prefs[Keys.SPEAK] = enabled }
    }

    private object Keys {
        val SCHEME = stringPreferencesKey("scheme")
        val HOST = stringPreferencesKey("host")
        val PORT = intPreferencesKey("port")
        val API_MODE = stringPreferencesKey("api_mode")
        val MODEL = stringPreferencesKey("model")
        val API_KEY = stringPreferencesKey("api_key")
        val STREAMING = booleanPreferencesKey("streaming")
        val SPEAK = booleanPreferencesKey("speak_replies")
        val WIFI_ONLY = booleanPreferencesKey("wifi_only")
        val TIMEOUT = intPreferencesKey("timeout_seconds")
        val SYSTEM_PROMPT = stringPreferencesKey("system_prompt")
    }
}
