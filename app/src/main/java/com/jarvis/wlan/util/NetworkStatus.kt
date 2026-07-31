package com.jarvis.wlan.util

import android.content.Context
import android.net.ConnectivityManager
import android.net.LinkAddress
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import java.net.Inet4Address

/** Momentaufnahme der Netzwerklage — reicht der App für "hängen wir im WLAN?". */
data class NetworkSnapshot(
    val online: Boolean = false,
    val isWifi: Boolean = false,
    val localIp: String? = null,
)

/**
 * Beobachtet das Standard-Netzwerk. Bewusst ohne Standortberechtigung, deshalb
 * gibt es die IP-Adresse statt der SSID — für "bin ich im richtigen Netz?"
 * reicht das und der Nutzer muss keine Location-Freigabe erteilen.
 */
class NetworkStatus(context: Context) {

    private val appContext = context.applicationContext
    private val connectivity =
        appContext.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

    fun current(): NetworkSnapshot {
        val network = connectivity.activeNetwork ?: return NetworkSnapshot()
        val caps = connectivity.getNetworkCapabilities(network) ?: return NetworkSnapshot()
        return snapshotOf(network, caps)
    }

    val updates: Flow<NetworkSnapshot> = callbackFlow {
        trySend(current())

        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                trySend(current())
            }

            override fun onLost(network: Network) {
                trySend(current())
            }

            override fun onCapabilitiesChanged(network: Network, caps: NetworkCapabilities) {
                trySend(snapshotOf(network, caps))
            }
        }

        val request = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .build()
        connectivity.registerNetworkCallback(request, callback)

        awaitClose { runCatching { connectivity.unregisterNetworkCallback(callback) } }
    }.distinctUntilChanged()

    /** IPv4 des Geräts im aktuellen Netz — Basis für den Subnetz-Scan. */
    fun localIpv4(): String? {
        val network = lanNetwork() ?: connectivity.activeNetwork ?: return null
        return connectivity.getLinkProperties(network)
            ?.linkAddresses
            ?.firstNotNullOfOrNull { it.ipv4OrNull() }
    }

    /**
     * Das WLAN-/Ethernet-Netzwerk, auch wenn es nicht das Standard-Netz ist.
     *
     * Wichtig: Hängt das Handy in einem WLAN ohne Internetzugang, macht Android
     * Mobilfunk zum Standard-Netz — Anfragen an 192.168.x.x liefen dann ins Leere.
     * Requests werden deshalb explizit an dieses Netzwerk gebunden.
     */
    @Suppress("DEPRECATION")
    fun lanNetwork(): Network? = connectivity.allNetworks.firstOrNull { network ->
        connectivity.getNetworkCapabilities(network)?.let { caps ->
            caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ||
                caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET)
        } == true
    }

    private fun snapshotOf(network: Network, caps: NetworkCapabilities): NetworkSnapshot {
        val isWifi = caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ||
            caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET)
        val ip = connectivity.getLinkProperties(network)
            ?.linkAddresses
            ?.firstNotNullOfOrNull { it.ipv4OrNull() }
        return NetworkSnapshot(
            online = caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET),
            isWifi = isWifi,
            localIp = ip,
        )
    }

    private fun LinkAddress.ipv4OrNull(): String? =
        (address as? Inet4Address)?.hostAddress?.takeUnless { it.startsWith("127.") }
}
