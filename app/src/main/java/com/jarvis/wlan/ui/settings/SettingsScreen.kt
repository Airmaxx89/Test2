package com.jarvis.wlan.ui.settings

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Wifi
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.text.KeyboardOptions
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.jarvis.wlan.R
import com.jarvis.wlan.data.ApiMode
import com.jarvis.wlan.data.ServerSettings

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onBack: () -> Unit,
    onOpenDiscovery: () -> Unit,
    pickedHost: String? = null,
    pickedPort: Int? = null,
    onPickConsumed: () -> Unit = {},
    viewModel: SettingsViewModel = viewModel(),
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val snackbarHostState = remember { SnackbarHostState() }

    // Treffer aus der Server-Suche ins Formular übernehmen.
    LaunchedEffect(pickedHost, pickedPort, state.loaded) {
        if (state.loaded && pickedHost != null && pickedPort != null) {
            viewModel.update { it.copy(host = pickedHost, port = pickedPort) }
            viewModel.onPortChange(pickedPort.toString())
            onPickConsumed()
        }
    }

    state.notice?.let { notice ->
        LaunchedEffect(notice) {
            snackbarHostState.showSnackbar(notice)
            viewModel.consumeNotice()
        }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.nav_settings)) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = stringResource(R.string.action_back),
                        )
                    }
                },
            )
        },
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .padding(innerPadding)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .imePadding()
                .padding(horizontal = 16.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            NetworkCard(state, onOpenDiscovery)

            SectionTitle(stringResource(R.string.settings_server))

            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.selectableGroup(),
            ) {
                ServerSettings.SCHEMES.forEach { scheme ->
                    FilterChip(
                        selected = state.draft.scheme == scheme,
                        onClick = { viewModel.update { it.copy(scheme = scheme) } },
                        label = { Text(scheme) },
                    )
                }
            }

            OutlinedTextField(
                value = state.draft.host,
                onValueChange = { value -> viewModel.update { it.copy(host = value.trim()) } },
                label = { Text(stringResource(R.string.settings_host)) },
                placeholder = { Text(stringResource(R.string.settings_host_hint)) },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Uri),
                modifier = Modifier.fillMaxWidth(),
            )

            OutlinedTextField(
                value = state.portText,
                onValueChange = viewModel::onPortChange,
                label = { Text(stringResource(R.string.settings_port)) },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth(),
            )

            SectionTitle(stringResource(R.string.settings_api_mode))

            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                FilterChip(
                    selected = state.draft.apiMode == ApiMode.JARVIS,
                    onClick = { viewModel.update { it.copy(apiMode = ApiMode.JARVIS) } },
                    label = { Text(stringResource(R.string.settings_api_mode_jarvis)) },
                )
                FilterChip(
                    selected = state.draft.apiMode == ApiMode.OPENAI,
                    onClick = { viewModel.update { it.copy(apiMode = ApiMode.OPENAI) } },
                    label = { Text(stringResource(R.string.settings_api_mode_openai)) },
                )
            }

            OutlinedTextField(
                value = state.draft.model,
                onValueChange = { value -> viewModel.update { it.copy(model = value) } },
                label = { Text(stringResource(R.string.settings_model)) },
                placeholder = { Text(stringResource(R.string.settings_model_hint)) },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
            )

            OutlinedTextField(
                value = state.draft.apiKey,
                onValueChange = { value -> viewModel.update { it.copy(apiKey = value) } },
                label = { Text(stringResource(R.string.settings_api_key)) },
                placeholder = { Text(stringResource(R.string.settings_api_key_hint)) },
                singleLine = true,
                visualTransformation = PasswordVisualTransformation(),
                modifier = Modifier.fillMaxWidth(),
            )

            OutlinedTextField(
                value = state.draft.systemPrompt,
                onValueChange = { value -> viewModel.update { it.copy(systemPrompt = value) } },
                label = { Text(stringResource(R.string.settings_system_prompt)) },
                minLines = 2,
                maxLines = 5,
                modifier = Modifier.fillMaxWidth(),
            )

            OutlinedTextField(
                value = state.timeoutText,
                onValueChange = viewModel::onTimeoutChange,
                label = { Text(stringResource(R.string.settings_timeout)) },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth(),
            )

            HorizontalDivider()

            SettingSwitch(
                title = stringResource(R.string.settings_streaming),
                description = stringResource(R.string.settings_streaming_desc),
                checked = state.draft.streaming,
                onCheckedChange = { value -> viewModel.update { it.copy(streaming = value) } },
            )
            SettingSwitch(
                title = stringResource(R.string.settings_speak),
                description = stringResource(R.string.settings_speak_desc),
                checked = state.draft.speakReplies,
                onCheckedChange = { value -> viewModel.update { it.copy(speakReplies = value) } },
            )
            SettingSwitch(
                title = stringResource(R.string.settings_wifi_only),
                description = stringResource(R.string.settings_wifi_only_desc),
                checked = state.draft.wifiOnly,
                onCheckedChange = { value -> viewModel.update { it.copy(wifiOnly = value) } },
            )

            state.testResult?.let { result ->
                Text(
                    text = result,
                    color = if (state.testOk) {
                        MaterialTheme.colorScheme.primary
                    } else {
                        MaterialTheme.colorScheme.error
                    },
                    style = MaterialTheme.typography.bodyMedium,
                )
            }

            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.fillMaxWidth(),
            ) {
                OutlinedButton(
                    onClick = viewModel::testConnection,
                    enabled = !state.testing,
                    modifier = Modifier.weight(1f),
                ) {
                    if (state.testing) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(16.dp),
                            strokeWidth = 2.dp,
                        )
                        Spacer(Modifier.size(8.dp))
                    }
                    Text(stringResource(R.string.settings_test))
                }
                Button(
                    onClick = { viewModel.save(onSaved = onBack) },
                    modifier = Modifier.weight(1f),
                ) {
                    Text(stringResource(R.string.settings_save))
                }
            }

            Spacer(Modifier.height(24.dp))
        }
    }
}

@Composable
private fun NetworkCard(state: SettingsUiState, onOpenDiscovery: () -> Unit) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    Icons.Default.Wifi,
                    contentDescription = null,
                    tint = if (state.network.isWifi) {
                        MaterialTheme.colorScheme.primary
                    } else {
                        MaterialTheme.colorScheme.error
                    },
                )
                Spacer(Modifier.size(10.dp))
                Column {
                    Text(
                        text = stringResource(R.string.settings_current_network),
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                    Text(
                        text = when {
                            state.network.isWifi && state.network.localIp != null ->
                                "WLAN · ${state.network.localIp}"
                            state.network.isWifi -> "WLAN"
                            state.network.online -> "Mobilfunk / kein WLAN"
                            else -> stringResource(R.string.status_offline)
                        },
                        style = MaterialTheme.typography.bodyMedium,
                    )
                }
            }
            Spacer(Modifier.height(12.dp))
            OutlinedButton(onClick = onOpenDiscovery, modifier = Modifier.fillMaxWidth()) {
                Text(stringResource(R.string.nav_discovery))
            }
        }
    }
}

@Composable
private fun SectionTitle(text: String) {
    Text(
        text = text,
        style = MaterialTheme.typography.titleSmall,
        fontWeight = FontWeight.SemiBold,
        color = MaterialTheme.colorScheme.primary,
        modifier = Modifier.padding(top = 8.dp),
    )
}

@Composable
private fun SettingSwitch(
    title: String,
    description: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(text = title, style = MaterialTheme.typography.bodyLarge)
            Text(
                text = description,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        Spacer(Modifier.size(12.dp))
        Switch(checked = checked, onCheckedChange = onCheckedChange)
    }
}
