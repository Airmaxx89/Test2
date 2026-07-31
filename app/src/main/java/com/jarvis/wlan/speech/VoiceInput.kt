package com.jarvis.wlan.speech

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import java.util.Locale

/**
 * Dünne Hülle um [SpeechRecognizer] für die Diktierfunktion im Chat.
 *
 * Muss vom Main-Thread aus bedient werden — der Recognizer bindet einen Service
 * und meldet sich über dessen Looper zurück.
 */
class VoiceInput(private val context: Context) {

    private var recognizer: SpeechRecognizer? = null
    private var listening = false

    fun isAvailable(): Boolean = SpeechRecognizer.isRecognitionAvailable(context)

    /**
     * [onPartial] liefert Zwischenstände fürs Live-Feedback, [onFinal] das
     * Endergebnis, [onError] eine für Menschen lesbare Fehlermeldung.
     */
    fun start(
        onPartial: (String) -> Unit,
        onFinal: (String) -> Unit,
        onError: (String) -> Unit,
    ) {
        if (!isAvailable()) {
            onError("Spracherkennung ist auf diesem Gerät nicht verfügbar.")
            return
        }
        if (listening) return

        val instance = recognizer ?: SpeechRecognizer.createSpeechRecognizer(context).also {
            recognizer = it
        }

        instance.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) = Unit
            override fun onBeginningOfSpeech() = Unit
            override fun onRmsChanged(rmsdB: Float) = Unit
            override fun onBufferReceived(buffer: ByteArray?) = Unit
            override fun onEndOfSpeech() = Unit
            override fun onEvent(eventType: Int, params: Bundle?) = Unit

            override fun onPartialResults(partialResults: Bundle?) {
                partialResults.firstMatch()?.let(onPartial)
            }

            override fun onResults(results: Bundle?) {
                listening = false
                val text = results.firstMatch()
                if (text.isNullOrBlank()) onError("Nichts verstanden.") else onFinal(text)
            }

            override fun onError(error: Int) {
                listening = false
                onError(describe(error))
            }
        })

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(
                RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM,
            )
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault().toLanguageTag())
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
        }

        listening = true
        runCatching { instance.startListening(intent) }
            .onFailure {
                listening = false
                onError(it.message ?: "Spracherkennung konnte nicht gestartet werden.")
            }
    }

    /** Beendet die Aufnahme und wertet aus, was bis hier verstanden wurde. */
    fun stop() {
        if (!listening) return
        listening = false
        runCatching { recognizer?.stopListening() }
    }

    fun cancel() {
        listening = false
        runCatching { recognizer?.cancel() }
    }

    fun release() {
        listening = false
        runCatching { recognizer?.destroy() }
        recognizer = null
    }

    private fun Bundle?.firstMatch(): String? =
        this?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
            ?.firstOrNull()
            ?.takeIf { it.isNotBlank() }

    private fun describe(error: Int): String = when (error) {
        SpeechRecognizer.ERROR_AUDIO -> "Audioproblem bei der Aufnahme."
        SpeechRecognizer.ERROR_CLIENT -> "Spracherkennung abgebrochen."
        SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Mikrofonzugriff fehlt."
        SpeechRecognizer.ERROR_NETWORK,
        SpeechRecognizer.ERROR_NETWORK_TIMEOUT,
        -> "Spracherkennung braucht Netz und bekam keins."
        SpeechRecognizer.ERROR_NO_MATCH -> "Nichts verstanden."
        SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Spracherkennung ist gerade beschäftigt."
        SpeechRecognizer.ERROR_SERVER -> "Der Spracherkennungsdienst meldet einen Fehler."
        SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "Nichts gehört."
        else -> "Spracherkennung fehlgeschlagen (Code $error)."
    }
}
