package com.jarvis.wlan.ui.discovery

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.jarvis.wlan.ServiceLocator
import com.jarvis.wlan.data.ServerSettings
import com.jarvis.wlan.net.DiscoveredServer
import com.jarvis.wlan.util.NetworkSnapshot
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class DiscoveryUiState(
    val results: List<DiscoveredServer> = emptyList(),
    val searching: Boolean = false,
    val scanning: Boolean = false,
    val network: NetworkSnapshot = NetworkSnapshot(),
    val verified: Set<String> = emptySet(),
)

class DiscoveryViewModel(application: Application) : AndroidViewModel(application) {

    private val discovery = ServiceLocator.serverDiscovery
    private val client = ServiceLocator.jarvisClient
    private val networkStatus = ServiceLocator.networkStatus

    private val _state = MutableStateFlow(DiscoveryUiState())
    val state: StateFlow<DiscoveryUiState> = _state.asStateFlow()

    private var mdnsJob: Job? = null
    private var scanJob: Job? = null

    init {
        viewModelScope.launch {
            networkStatus.updates.collect { snapshot ->
                _state.value = _state.value.copy(network = snapshot)
            }
        }
        startMdns()
    }

    fun startMdns() {
        if (mdnsJob?.isActive == true) return
        _state.value = _state.value.copy(searching = true)
        mdnsJob = viewModelScope.launch {
            discovery.mdns().collect(::addResult)
        }
    }

    fun startScan() {
        if (scanJob?.isActive == true) return
        _state.value = _state.value.copy(scanning = true)
        scanJob = viewModelScope.launch {
            try {
                discovery.scanSubnet().collect(::addResult)
            } finally {
                _state.value = _state.value.copy(scanning = false)
            }
        }
    }

    fun stopAll() {
        mdnsJob?.cancel()
        scanJob?.cancel()
        mdnsJob = null
        scanJob = null
        _state.value = _state.value.copy(searching = false, scanning = false)
    }

    private fun addResult(server: DiscoveredServer) {
        val existing = _state.value.results
        if (existing.any { it.key == server.key }) return
        _state.value = _state.value.copy(results = existing + server)
        verify(server)
    }

    /**
     * Ein offener Port heißt noch nicht "Jarvis". Ein Health-Check hinterher
     * markiert die Treffer, die wirklich antworten.
     */
    private fun verify(server: DiscoveredServer) {
        viewModelScope.launch {
            val probe = ServerSettings(host = server.host, port = server.port)
            val info = client.ping(probe, networkStatus.lanNetwork())
            if (info.reachable) {
                _state.value = _state.value.copy(verified = _state.value.verified + server.key)
            }
        }
    }

    override fun onCleared() {
        stopAll()
        super.onCleared()
    }
}
