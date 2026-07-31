package com.jarvis.wlan.ui.theme

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext

private val JarvisCyan = Color(0xFF1B9FC7)
private val JarvisCyanLight = Color(0xFF5FD3F3)
private val JarvisDeep = Color(0xFF0B1622)

private val DarkColors = darkColorScheme(
    primary = JarvisCyanLight,
    onPrimary = Color(0xFF00293A),
    primaryContainer = Color(0xFF004E68),
    onPrimaryContainer = Color(0xFFB9EAFF),
    secondary = Color(0xFF8FCDE2),
    background = JarvisDeep,
    onBackground = Color(0xFFDDE4EA),
    surface = Color(0xFF10202E),
    onSurface = Color(0xFFDDE4EA),
    surfaceVariant = Color(0xFF1B2E3E),
    onSurfaceVariant = Color(0xFFB6C6D2),
)

private val LightColors = lightColorScheme(
    primary = JarvisCyan,
    onPrimary = Color.White,
    primaryContainer = Color(0xFFB9EAFF),
    onPrimaryContainer = Color(0xFF001F2A),
    secondary = Color(0xFF4C6472),
    background = Color(0xFFF6FAFD),
    onBackground = Color(0xFF171C1F),
    surface = Color.White,
    onSurface = Color(0xFF171C1F),
    surfaceVariant = Color(0xFFDCE4E9),
    onSurfaceVariant = Color(0xFF40484D),
)

@Composable
fun JarvisTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit,
) {
    val context = LocalContext.current
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ->
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        darkTheme -> DarkColors
        else -> LightColors
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography(),
        content = content,
    )
}
