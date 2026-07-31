package com.jarvis.wlan.ui.chat

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.jarvis.wlan.R
import com.jarvis.wlan.ServiceLocator
import com.jarvis.wlan.data.ChatMessage
import com.jarvis.wlan.data.Role
import com.jarvis.wlan.data.ServerSettings
import com.jarvis.wlan.speech.Speaker
import com.jarvis.wlan.speech.VoiceInput
import com.jarvis.wlan.util.NetworkSnapshot
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch

sealed interface ConnectionState {
    data object Unknown : ConnectionState
    data object Checking : ConnectionState
    data class Online(val detail: String, val latencyMs: Long) : ConnectionState
    data class Offline(val reason: String) : ConnectionState
}

data class ChatUiState(
    val messages: List<ChatMessage> = emptyList(),
    val input: String = "",
    val isStreaming: Boolean = false,
    val listening: Boolean = false,
    val settings: ServerSettings = ServerSettings(),
    val network: NetworkSnapshot = NetworkSnapshot(),
    val connection: ConnectionState = ConnectionState.Unknown,
    val notice: String? = null,
) {
    val canSend: Boolean get() = input.isNotBlank() && !isStreaming
    /** Nur-WLAN aktiv, Gerät aber nicht im WLAN. */
    val blockedByWifiRule: Boolean get() = settings.wifiOnly && !network.isWifi
}

class ChatViewModel(application: Application) : AndroidViewModel(application) {

    private val settingsRepository = ServiceLocator.settingsRepository
    private val client = ServiceLocator.jarvisClient
    private val networkStatus = ServiceLocator.networkStatus

    private val voiceInput = VoiceInput(application)
    // Die TTS-Engine erst hochfahren, wenn wirklich vorgelesen werden soll.
    private val speakerDelegate = lazy { Speaker(application) }
    private val speaker by speakerDelegate

    private val _state = MutableStateFlow(ChatUiState())
    val state: StateFlow<ChatUiState> = _state.asStateFlow()

    private var streamJob: Job? = null
    private var stoppedByUser = false

    init {
        viewModelScope.launch {
            settingsRepository.settings.collect { settings ->
                _state.value = _state.value.copy(settings = settings)
            }
        }
        viewModelScope.launch {
            networkStatus.updates.collect { snapshot ->
                _state.value = _state.value.copy(network = snapshot)
            }
        }
        // Endpunkt-Wechsel (auch aus dem Discovery-Screen) neu prüfen.
        viewModelScope.launch {
            settingsRepository.settings
                .map { it.baseUrl to it.apiMode }
                .distinctUntilChanged()
                .collect { checkConnection() }
        }
    }

    fun onInputChange(value: String) {
        _state.value = _state.value.copy(input = value)
    }

    fun checkConnection() {
        viewModelScope.launch {
            val settings = _state.value.settings
            if (!settings.isConfigured) {
                _state.value = _state.value.copy(connection = ConnectionState.Unknown)
                return@launch
            }
            _state.value = _state.value.copy(connection = ConnectionState.Checking)
            val info = client.ping(settings, networkStatus.lanNetwork())
            _state.value = _state.value.copy(
                connection = if (info.reachable) {
                    ConnectionState.Online(info.detail, info.latencyMs)
                } else {
                    ConnectionState.Offline(info.detail)
                },
            )
        }
    }

    fun send() {
        val current = _state.value
        val text = current.input.trim()
        if (text.isEmpty() || current.isStreaming) return

        if (!current.settings.isConfigured) {
            _state.value = current.copy(notice = string(R.string.error_no_host))
            return
        }
        if (current.blockedByWifiRule) {
            _state.value = current.copy(notice = string(R.string.error_wifi_required))
            return
        }

        val userMessage = ChatMessage(role = Role.USER, text = text)
        val placeholder = ChatMessage(role = Role.ASSISTANT, text = "", streaming = true)
        _state.value = current.copy(
            messages = current.messages + userMessage + placeholder,
            input = "",
            isStreaming = true,
        )
        streamAnswer(placeholder.id)
    }

    /** Letzte Frage erneut stellen — nützlich, wenn das WLAN kurz weg war. */
    fun retryLast() {
        val messages = _state.value.messages
        val lastUser = messages.lastOrNull { it.role == Role.USER } ?: return
        if (_state.value.isStreaming) return

        // Fehlgeschlagene Antwort verwerfen, Frage stehen lassen.
        val trimmed = messages.dropLastWhile { it.role == Role.ASSISTANT }
        val placeholder = ChatMessage(role = Role.ASSISTANT, text = "", streaming = true)
        _state.value = _state.value.copy(
            messages = trimmed + placeholder,
            isStreaming = true,
        )
        streamAnswer(placeholder.id, retryOf = lastUser)
    }

    private fun streamAnswer(placeholderId: String, retryOf: ChatMessage? = null) {
        stoppedByUser = false
        stopSpeaking()

        streamJob = viewModelScope.launch {
            val settings = _state.value.settings
            // Der Platzhalter selbst gehört nicht in die Historie.
            val history = _state.value.messages.filterNot { it.id == placeholderId }
            val outgoing = if (retryOf != null && history.lastOrNull()?.id != retryOf.id) {
                history + retryOf
            } else {
                history
            }

            val buffer = StringBuilder()
            var failure: String? = null

            try {
                client.chat(settings, outgoing, networkStatus.lanNetwork()).collect { delta ->
                    buffer.append(delta)
                    updateMessage(placeholderId) { it.copy(text = buffer.toString()) }
                }
            } catch (e: CancellationException) {
                if (!stoppedByUser) failure = "Abgebrochen."
                throw e
            } catch (e: Exception) {
                failure = e.message ?: "Unerwarteter Fehler."
            } finally {
                val partial = buffer.toString()
                updateMessage(placeholderId) {
                    it.copy(text = partial, streaming = false, error = failure)
                }
                _state.value = _state.value.copy(isStreaming = false)

                if (failure == null && partial.isNotBlank() && settings.speakReplies) {
                    speaker.speak(partial)
                }
                if (failure != null) {
                    _state.value = _state.value.copy(
                        connection = ConnectionState.Offline(failure),
                    )
                }
            }
        }
    }

    fun stopStreaming() {
        stoppedByUser = true
        streamJob?.cancel()
        streamJob = null
        stopSpeaking()
    }

    fun clearConversation() {
        stopStreaming()
        _state.value = _state.value.copy(messages = emptyList(), isStreaming = false)
    }

    fun toggleSpeakReplies() {
        val enabled = !_state.value.settings.speakReplies
        if (!enabled) stopSpeaking()
        viewModelScope.launch { settingsRepository.setSpeakReplies(enabled) }
    }

    private fun stopSpeaking() {
        if (speakerDelegate.isInitialized()) speaker.stop()
    }

    // --- Spracheingabe -----------------------------------------------------

    /** Aufruf nur vom Main-Thread und erst nach erteilter Mikrofonberechtigung. */
    fun startListening() {
        if (_state.value.listening) return
        _state.value = _state.value.copy(listening = true)
        voiceInput.start(
            onPartial = { partial -> _state.value = _state.value.copy(input = partial) },
            onFinal = { text ->
                _state.value = _state.value.copy(input = text, listening = false)
                send()
            },
            onError = { message ->
                _state.value = _state.value.copy(listening = false, notice = message)
            },
        )
    }

    fun stopListening() {
        if (!_state.value.listening) return
        _state.value = _state.value.copy(listening = false)
        voiceInput.stop()
    }

    fun onMicPermissionDenied() {
        _state.value = _state.value.copy(
            listening = false,
            notice = string(R.string.error_mic_permission),
        )
    }

    private fun string(resId: Int): String = getApplication<Application>().getString(resId)

    fun consumeNotice() {
        _state.value = _state.value.copy(notice = null)
    }

    private fun updateMessage(id: String, transform: (ChatMessage) -> ChatMessage) {
        _state.value = _state.value.copy(
            messages = _state.value.messages.map { if (it.id == id) transform(it) else it },
        )
    }

    override fun onCleared() {
        voiceInput.release()
        if (speakerDelegate.isInitialized()) speaker.release()
        super.onCleared()
    }
}
