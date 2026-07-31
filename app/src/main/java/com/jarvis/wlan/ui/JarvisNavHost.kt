package com.jarvis.wlan.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.jarvis.wlan.ui.chat.ChatScreen
import com.jarvis.wlan.ui.discovery.DiscoveryScreen
import com.jarvis.wlan.ui.settings.SettingsScreen

object Routes {
    const val CHAT = "chat"
    const val SETTINGS = "settings"
    const val DISCOVERY = "discovery"
}

/** Schlüssel, über die die Server-Suche ihren Treffer an die Einstellungen zurückgibt. */
private const val KEY_PICKED_HOST = "picked_host"
private const val KEY_PICKED_PORT = "picked_port"

@Composable
fun JarvisNavHost() {
    val navController = rememberNavController()

    NavHost(navController = navController, startDestination = Routes.CHAT) {
        composable(Routes.CHAT) {
            ChatScreen(onOpenSettings = { navController.navigate(Routes.SETTINGS) })
        }

        composable(Routes.SETTINGS) { entry ->
            val pickedHost by entry.savedStateHandle
                .getStateFlow<String?>(KEY_PICKED_HOST, null)
                .collectAsStateWithLifecycle()
            val pickedPort by entry.savedStateHandle
                .getStateFlow(KEY_PICKED_PORT, -1)
                .collectAsStateWithLifecycle()

            SettingsScreen(
                onBack = { navController.popBackStack() },
                onOpenDiscovery = { navController.navigate(Routes.DISCOVERY) },
                pickedHost = pickedHost,
                pickedPort = pickedPort.takeIf { it > 0 },
                onPickConsumed = {
                    entry.savedStateHandle[KEY_PICKED_HOST] = null
                    entry.savedStateHandle[KEY_PICKED_PORT] = -1
                },
            )
        }

        composable(Routes.DISCOVERY) {
            DiscoveryScreen(
                onBack = { navController.popBackStack() },
                onPick = { host, port ->
                    navController.previousBackStackEntry?.savedStateHandle?.let { handle ->
                        handle[KEY_PICKED_HOST] = host
                        handle[KEY_PICKED_PORT] = port
                    }
                    navController.popBackStack()
                },
            )
        }
    }
}
