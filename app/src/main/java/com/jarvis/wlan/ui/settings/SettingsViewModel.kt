package com.jarvis.wlan.ui.settings

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.jarvis.wlan.R
import com.jarvis.wlan.ServiceLocator
import com.jarvis.wlan.data.ServerSettings
import com.jarvis.wlan.util.NetworkSnapshot
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

data class SettingsUiState(
    val draft: ServerSettings = ServerSettings(),
    /** Roher Portwert, damit das Feld auch kurzzeitig leer sein darf. */
    val portText: String = ServerSettings.DEFAULT_PORT.toString(),
    val timeoutText: String = ServerSettings.DEFAULT_TIMEOUT_SECONDS.toString(),
    val network: NetworkSnapshot = NetworkSnapshot(),
    val testing: Boolean = false,
    val testResult: String? = null,
    val testOk: Boolean = false,
    val notice: String? = null,
    val loaded: Boolean = false,
)

class SettingsViewModel(application: Application) : AndroidViewModel(application) {

    private val repository = ServiceLocator.settingsRepository
    private val client = ServiceLocator.jarvisClient
    private val networkStatus = ServiceLocator.networkStatus

    private val _state = MutableStateFlow(SettingsUiState())
    val state: StateFlow<SettingsUiState> = _state.asStateFlow()

    init {
        viewModelScope.launch {
            // Einmalig laden — danach gehört der Entwurf dem Nutzer.
            val stored = repository.settings.first()
            _state.value = _state.value.copy(
                draft = stored,
                portText = stored.port.toString(),
                timeoutText = stored.timeoutSeconds.toString(),
                loaded = true,
            )
        }
        viewModelScope.launch {
            networkStatus.updates.collect { snapshot ->
                _state.value = _state.value.copy(network = snapshot)
            }
        }
    }

    fun update(transform: (ServerSettings) -> ServerSettings) {
        _state.value = _state.value.copy(
            draft = transform(_state.value.draft),
            testResult = null,
        )
    }

    fun onPortChange(value: String) {
        val digits = value.filter(Char::isDigit).take(5)
        _state.value = _state.value.copy(
            portText = digits,
            draft = _state.value.draft.copy(
                port = digits.toIntOrNull()?.coerceIn(1, 65535) ?: _state.value.draft.port,
            ),
            testResult = null,
        )
    }

    fun onTimeoutChange(value: String) {
        val digits = value.filter(Char::isDigit).take(4)
        _state.value = _state.value.copy(
            timeoutText = digits,
            draft = _state.value.draft.copy(
                timeoutSeconds = digits.toIntOrNull()?.coerceIn(5, 900)
                    ?: _state.value.draft.timeoutSeconds,
            ),
        )
    }

    fun save(onSaved: () -> Unit = {}) {
        viewModelScope.launch {
            val draft = _state.value.draft
            if (draft.host.isBlank()) {
                _state.value = _state.value.copy(notice = string(R.string.error_host_missing))
                return@launch
            }
            repository.save(draft)
            _state.value = _state.value.copy(notice = string(R.string.settings_saved))
            onSaved()
        }
    }

    fun testConnection() {
        viewModelScope.launch {
            val draft = _state.value.draft
            if (draft.host.isBlank()) {
                _state.value = _state.value.copy(notice = string(R.string.error_host_missing))
                return@launch
            }
            _state.value = _state.value.copy(testing = true, testResult = null)
            val info = client.ping(draft, networkStatus.lanNetwork())
            _state.value = _state.value.copy(
                testing = false,
                testOk = info.reachable,
                testResult = if (info.reachable) {
                    getApplication<Application>()
                        .getString(R.string.test_reachable, info.detail, info.latencyMs.toInt())
                } else {
                    getApplication<Application>()
                        .getString(R.string.test_unreachable, info.detail)
                },
            )
        }
    }

    fun consumeNotice() {
        _state.value = _state.value.copy(notice = null)
    }

    private fun string(resId: Int): String = getApplication<Application>().getString(resId)
}
