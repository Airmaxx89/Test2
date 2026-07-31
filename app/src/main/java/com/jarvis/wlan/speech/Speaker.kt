package com.jarvis.wlan.speech

import android.content.Context
import android.speech.tts.TextToSpeech
import java.util.Locale

/**
 * Liest Jarvis-Antworten vor. Die Engine startet asynchron; bis sie bereit ist,
 * wird der zuletzt angeforderte Text gepuffert und danach nachgeholt.
 */
class Speaker(context: Context) {

    private var engine: TextToSpeech? = null
    private var ready = false
    private var pending: String? = null

    init {
        engine = TextToSpeech(context.applicationContext) { status ->
            ready = status == TextToSpeech.SUCCESS
            if (ready) {
                engine?.language = Locale.getDefault()
                pending?.let { text ->
                    pending = null
                    speak(text)
                }
            }
        }
    }

    fun speak(text: String) {
        val trimmed = text.trim()
        if (trimmed.isEmpty()) return
        val tts = engine
        if (tts == null || !ready) {
            pending = trimmed
            return
        }
        tts.speak(trimmed, TextToSpeech.QUEUE_FLUSH, null, UTTERANCE_ID)
    }

    fun stop() {
        pending = null
        runCatching { engine?.stop() }
    }

    fun release() {
        pending = null
        runCatching {
            engine?.stop()
            engine?.shutdown()
        }
        engine = null
        ready = false
    }

    private companion object {
        const val UTTERANCE_ID = "jarvis-reply"
    }
}
