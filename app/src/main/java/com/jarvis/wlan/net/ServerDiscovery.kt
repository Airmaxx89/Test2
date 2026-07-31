package com.jarvis.wlan.net

import android.content.Context
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.net.wifi.WifiManager
import com.jarvis.wlan.util.NetworkStatus
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.channelFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.Semaphore
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.sync.withPermit
import java.io.IOException
import java.net.InetSocketAddress
import java.net.Socket
import kotlin.coroutines.resume

enum class DiscoverySource { MDNS, SCAN }

data class DiscoveredServer(
    val host: String,
    val port: Int,
    val label: String,
    val source: DiscoverySource,
) {
    val key: String get() = "$host:$port"
}

/**
 * Findet Jarvis-Server im lokalen Netz — erst über mDNS/Bonjour, alternativ
 * per Portscan durchs eigene /24-Subnetz.
 */
class ServerDiscovery(
    context: Context,
    private val networkStatus: NetworkStatus,
) {
    private val appContext = context.applicationContext

    /**
     * Lauscht auf DNS-SD-Ankündigungen. Der Server muss sich dafür bekannt
     * machen (z. B. `_jarvis._tcp`), siehe server/jarvis_server.py.
     */
    fun mdns(): Flow<DiscoveredServer> = callbackFlow {
        val nsd = appContext.getSystemService(Context.NSD_SERVICE) as? NsdManager
            ?: return@callbackFlow
        val wifi = appContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
        // Ohne Multicast-Lock verwirft der WLAN-Chip die mDNS-Pakete im Standby.
        val multicastLock = wifi?.createMulticastLock("jarvis-nsd")?.apply {
            setReferenceCounted(true)
            runCatching { acquire() }
        }

        // resolveService verträgt keine parallelen Aufrufe mit demselben Listener-Typ.
        val resolveLock = Mutex()
        val started = mutableListOf<NsdManager.DiscoveryListener>()

        SERVICE_TYPES.forEach { type ->
            val listener = object : NsdManager.DiscoveryListener {
                override fun onDiscoveryStarted(serviceType: String) = Unit

                override fun onServiceFound(serviceInfo: NsdServiceInfo) {
                    launch {
                        resolve(nsd, serviceInfo, resolveLock)?.let { trySend(it) }
                    }
                }

                override fun onServiceLost(serviceInfo: NsdServiceInfo) = Unit
                override fun onDiscoveryStopped(serviceType: String) = Unit

                override fun onStartDiscoveryFailed(serviceType: String, errorCode: Int) {
                    runCatching { nsd.stopServiceDiscovery(this) }
                }

                override fun onStopDiscoveryFailed(serviceType: String, errorCode: Int) = Unit
            }

            runCatching { nsd.discoverServices(type, NsdManager.PROTOCOL_DNS_SD, listener) }
                .onSuccess { started += listener }
        }

        awaitClose {
            started.forEach { runCatching { nsd.stopServiceDiscovery(it) } }
            multicastLock?.let { lock -> runCatching { if (lock.isHeld) lock.release() } }
        }
    }

    @Suppress("DEPRECATION") // resolveService ist bis API 34 der einzige Weg zurück in alle Versionen.
    private suspend fun resolve(
        nsd: NsdManager,
        info: NsdServiceInfo,
        lock: Mutex,
    ): DiscoveredServer? = lock.withLock {
        suspendCancellableCoroutine { continuation ->
            val listener = object : NsdManager.ResolveListener {
                override fun onResolveFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {
                    if (continuation.isActive) continuation.resume(null)
                }

                override fun onServiceResolved(serviceInfo: NsdServiceInfo) {
                    if (!continuation.isActive) return
                    val host = serviceInfo.host?.hostAddress
                    continuation.resume(
                        if (host.isNullOrBlank() || serviceInfo.port <= 0) {
                            null
                        } else {
                            DiscoveredServer(
                                host = host,
                                port = serviceInfo.port,
                                label = serviceInfo.serviceName ?: host,
                                source = DiscoverySource.MDNS,
                            )
                        },
                    )
                }
            }
            runCatching { nsd.resolveService(info, listener) }
                .onFailure { if (continuation.isActive) continuation.resume(null) }
        }
    }

    /**
     * Klopft im eigenen /24 an den üblichen Ports an. Kein Ersatz für mDNS,
     * aber der zuverlässige Weg, wenn der Server sich nicht ankündigt.
     */
    fun scanSubnet(ports: List<Int> = COMMON_PORTS): Flow<DiscoveredServer> = channelFlow {
        val localIp = networkStatus.localIpv4() ?: return@channelFlow
        val prefix = localIp.substringBeforeLast('.', missingDelimiterValue = "")
        if (prefix.isEmpty()) return@channelFlow

        val gate = Semaphore(MAX_PARALLEL_PROBES)
        (1..254)
            .map { "$prefix.$it" }
            .filterNot { it == localIp }
            .forEach { host ->
                launch(Dispatchers.IO) {
                    for (port in ports) {
                        val open = gate.withPermit { isPortOpen(host, port) }
                        if (open) {
                            send(
                                DiscoveredServer(
                                    host = host,
                                    port = port,
                                    label = host,
                                    source = DiscoverySource.SCAN,
                                ),
                            )
                        }
                    }
                }
            }
    }

    private fun isPortOpen(host: String, port: Int): Boolean = try {
        Socket().use { socket ->
            socket.connect(InetSocketAddress(host, port), PROBE_TIMEOUT_MS)
            true
        }
    } catch (_: IOException) {
        false
    } catch (_: IllegalArgumentException) {
        false
    }

    private companion object {
        val SERVICE_TYPES = listOf("_jarvis._tcp.", "_http._tcp.")
        val COMMON_PORTS = listOf(8000, 8080, 5000, 11434, 1234, 3000)
        const val MAX_PARALLEL_PROBES = 48
        const val PROBE_TIMEOUT_MS = 400
    }
}
