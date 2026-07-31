package com.jarvis.wlan.net

import android.net.Network
import com.jarvis.wlan.data.ApiMode
import com.jarvis.wlan.data.ChatMessage
import com.jarvis.wlan.data.Role
import com.jarvis.wlan.data.ServerSettings
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.FlowCollector
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlinx.serialization.json.putJsonArray
import okhttp3.Dns
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response
import java.io.IOException
import java.net.InetAddress
import java.util.concurrent.TimeUnit

class JarvisException(message: String, cause: Throwable? = null) : Exception(message, cause)

/** Ergebnis des Health-Checks. */
data class ServerInfo(
    val reachable: Boolean,
    val detail: String,
    val latencyMs: Long,
)

/**
 * HTTP-Client für das Jarvis-Gehirn im lokalen Netz.
 *
 * Spricht zwei Dialekte ([ApiMode]) und in beiden Fällen sowohl Streaming
 * (Server-Sent Events) als auch eine einzelne JSON-Antwort. Beim Parsen ist
 * der Client bewusst tolerant — Self-Hosting-Stacks benennen das Antwortfeld
 * unterschiedlich.
 */
class JarvisClient(
    private val json: Json = Json { ignoreUnknownKeys = true; isLenient = true },
) {

    private val base: OkHttpClient = OkHttpClient.Builder()
        .retryOnConnectionFailure(true)
        .build()

    private fun httpClient(settings: ServerSettings, network: Network?): OkHttpClient =
        base.newBuilder()
            .connectTimeout(CONNECT_TIMEOUT_SECONDS, TimeUnit.SECONDS)
            .readTimeout(settings.timeoutSeconds.toLong(), TimeUnit.SECONDS)
            .writeTimeout(settings.timeoutSeconds.toLong(), TimeUnit.SECONDS)
            // Kein Call-Timeout: ein laufender Stream darf länger dauern als ein Read.
            .callTimeout(0, TimeUnit.SECONDS)
            .bindTo(network)
            .build()

    /**
     * Bindet den Client ans übergebene Netzwerk. Ohne das würde Android bei einem
     * WLAN ohne Internetzugang über Mobilfunk routen — und das Heimnetz wäre weg.
     */
    private fun OkHttpClient.Builder.bindTo(network: Network?): OkHttpClient.Builder = apply {
        if (network == null) return@apply
        socketFactory(network.socketFactory)
        dns(object : Dns {
            override fun lookup(hostname: String): List<InetAddress> =
                runCatching { network.getAllByName(hostname).toList() }
                    .getOrElse { Dns.SYSTEM.lookup(hostname) }
        })
    }

    /** Kurzer Erreichbarkeitstest gegen den Health-Endpunkt. */
    suspend fun ping(
        settings: ServerSettings,
        network: Network? = null,
    ): ServerInfo = withContext(Dispatchers.IO) {
        if (!settings.isConfigured) return@withContext ServerInfo(false, "Kein Host gesetzt", 0)

        val client = base.newBuilder()
            .connectTimeout(PING_TIMEOUT_SECONDS, TimeUnit.SECONDS)
            .readTimeout(PING_TIMEOUT_SECONDS, TimeUnit.SECONDS)
            .bindTo(network)
            .build()
        val request = Request.Builder()
            .url(settings.url(settings.healthPath))
            .header("Accept", "application/json")
            .applyAuth(settings)
            .get()
            .build()

        val started = System.nanoTime()
        fun elapsed() = (System.nanoTime() - started) / 1_000_000

        try {
            client.newCall(request).execute().use { response ->
                val body = runCatching { response.body?.string().orEmpty() }.getOrDefault("")
                if (response.isSuccessful) {
                    ServerInfo(true, describeHealth(body), elapsed())
                } else {
                    ServerInfo(false, "HTTP ${response.code}", elapsed())
                }
            }
        } catch (e: IOException) {
            ServerInfo(false, e.message ?: "Netzwerkfehler", elapsed())
        }
    }

    /**
     * Schickt [history] (die neue Nutzerfrage als letzter Eintrag) an den Server
     * und liefert die Antwort als Strom von Text-Deltas. Nicht-streamende Server
     * liefern genau ein Element mit dem vollständigen Text.
     *
     * Fehler kommen als [JarvisException] aus dem Flow.
     */
    fun chat(
        settings: ServerSettings,
        history: List<ChatMessage>,
        network: Network? = null,
    ): Flow<String> = flow {
        if (!settings.isConfigured) throw JarvisException("Kein Jarvis-Server eingerichtet.")

        val call = httpClient(settings, network).newCall(buildChatRequest(settings, history))
        // Bricht der Collector ab (Stop-Button, Screen verlassen), muss der Socket weg.
        currentCoroutineContext()[Job]?.invokeOnCompletion { call.cancel() }

        val response = try {
            call.execute()
        } catch (e: IOException) {
            throw JarvisException(friendlyIoMessage(e, settings), e)
        }

        response.use {
            if (!response.isSuccessful) throw JarvisException(errorMessage(response))
            val body = response.body ?: throw JarvisException("Leere Antwort vom Server.")

            try {
                if (response.header("Content-Type").orEmpty()
                        .contains("text/event-stream", ignoreCase = true)
                ) {
                    val source = body.source()
                    consumeSse(this) { source.readUtf8Line() }
                } else {
                    val text = parseSingleReply(body.string())
                    if (text.isNotEmpty()) emit(text)
                }
            } catch (e: IOException) {
                throw JarvisException(friendlyIoMessage(e, settings), e)
            }
        }
    }.flowOn(Dispatchers.IO)

    /**
     * Liest SSE-Zeilen über [readLine]: `data:`-Zeilen sammeln, bei Leerzeile das
     * Event auswerten, bei `[DONE]` beenden.
     */
    private suspend fun consumeSse(collector: FlowCollector<String>, readLine: () -> String?) {
        val pending = StringBuilder()

        suspend fun flushEvent() {
            if (pending.isEmpty()) return
            val payload = pending.toString()
            pending.setLength(0)
            extractDelta(payload)?.takeIf { it.isNotEmpty() }?.let { collector.emit(it) }
        }

        while (true) {
            val line = readLine() ?: break
            when {
                line.isBlank() -> flushEvent()
                line.startsWith(":") -> Unit // Kommentar / Keep-alive
                line.startsWith("data:") -> {
                    val chunk = line.removePrefix("data:").removePrefix(" ")
                    if (chunk.trim() == DONE_MARKER) {
                        pending.setLength(0)
                        return
                    }
                    if (pending.isNotEmpty()) pending.append('\n')
                    pending.append(chunk)
                }
                // event: / id: / retry: brauchen wir nicht.
            }
        }
        flushEvent()
    }

    private fun buildChatRequest(settings: ServerSettings, history: List<ChatMessage>): Request {
        val payload = when (settings.apiMode) {
            ApiMode.OPENAI -> openAiBody(settings, history)
            ApiMode.JARVIS -> jarvisBody(settings, history)
        }
        return Request.Builder()
            .url(settings.url(settings.chatPath))
            .header("Accept", if (settings.streaming) "text/event-stream" else "application/json")
            .applyAuth(settings)
            .post(payload.toString().toRequestBody(JSON_MEDIA_TYPE))
            .build()
    }

    private fun openAiBody(settings: ServerSettings, history: List<ChatMessage>): JsonObject =
        buildJsonObject {
            put("model", settings.model.ifBlank { "jarvis-local" })
            put("stream", settings.streaming)
            putJsonArray("messages") {
                if (settings.systemPrompt.isNotBlank()) {
                    add(messageObject("system", settings.systemPrompt))
                }
                history.forEach { add(messageObject(it.role.wireName, it.text)) }
            }
        }

    private fun jarvisBody(settings: ServerSettings, history: List<ChatMessage>): JsonObject =
        buildJsonObject {
            put("message", history.lastOrNull { it.role == Role.USER }?.text.orEmpty())
            put("stream", settings.streaming)
            if (settings.systemPrompt.isNotBlank()) put("system_prompt", settings.systemPrompt)
            if (settings.model.isNotBlank()) put("model", settings.model)
            putJsonArray("history") {
                history.dropLast(1).forEach { add(messageObject(it.role.wireName, it.text)) }
            }
        }

    private fun messageObject(role: String, content: String): JsonObject = buildJsonObject {
        put("role", role)
        put("content", content)
    }

    private fun Request.Builder.applyAuth(settings: ServerSettings): Request.Builder = apply {
        if (settings.apiKey.isNotBlank()) header("Authorization", "Bearer ${settings.apiKey}")
    }

    /** Holt den Textzuwachs aus einem SSE-Payload — OpenAI-Form oder Jarvis-Form. */
    internal fun extractDelta(payload: String): String? {
        val trimmed = payload.trim()
        if (trimmed.isEmpty()) return null
        if (!trimmed.startsWith("{") && !trimmed.startsWith("[")) return payload // reiner Text

        val element = runCatching { json.parseToJsonElement(trimmed) }.getOrNull() ?: return payload
        failOnServerError(element)
        return textFrom(element)
    }

    /** Antwort eines nicht-streamenden Servers auf Text reduzieren. */
    internal fun parseSingleReply(raw: String): String {
        val trimmed = raw.trim()
        if (trimmed.isEmpty()) return ""
        if (!trimmed.startsWith("{") && !trimmed.startsWith("[")) return raw

        val element = runCatching { json.parseToJsonElement(trimmed) }.getOrNull() ?: return raw
        failOnServerError(element)
        return textFrom(element) ?: raw
    }

    private fun failOnServerError(element: JsonElement) {
        val error = (element as? JsonObject)?.get("error") ?: return
        if (error is JsonNull) return
        val detail = textFrom(error) ?: error.toString()
        if (detail.isNotBlank()) throw JarvisException("Server meldet: ${detail.take(300)}")
    }

    /**
     * Sucht das erste plausible Textfeld. Deckt `choices[].delta.content` (OpenAI),
     * `choices[].message.content` sowie `reply`/`response`/`text`/`token`/`delta`/
     * `content`/`answer`/`output` ab.
     */
    private fun textFrom(element: JsonElement, depth: Int = 0): String? {
        if (depth > MAX_JSON_DEPTH) return null
        return when (element) {
            is JsonNull -> null
            is JsonPrimitive -> if (element.isString) element.content else null
            is JsonArray -> element.firstNotNullOfOrNull { textFrom(it, depth + 1) }
            is JsonObject -> {
                for (key in TEXT_KEYS) {
                    val value = element[key] ?: continue
                    textFrom(value, depth + 1)?.let { return it }
                }
                for (key in CONTAINER_KEYS) {
                    val value = element[key] ?: continue
                    textFrom(value, depth + 1)?.let { return it }
                }
                null
            }
        }
    }

    private fun describeHealth(body: String): String {
        val obj = runCatching { json.parseToJsonElement(body.trim()) }.getOrNull() as? JsonObject
            ?: return "OK"
        val name = (obj["name"] as? JsonPrimitive)?.takeIf { it.isString }?.content
        val version = (obj["version"] as? JsonPrimitive)?.takeIf { it.isString }?.content
        return listOfNotNull(name, version).joinToString(" ").ifBlank { "OK" }
    }

    private fun errorMessage(response: Response): String {
        val body = runCatching { response.body?.string().orEmpty() }.getOrDefault("")
        val detail = runCatching {
            val element = json.parseToJsonElement(body.trim())
            // Fehlerantworten packen den Grund üblicherweise in "error" — mal als
            // String, mal als Objekt mit "message".
            val errorField = (element as? JsonObject)?.get("error")?.takeUnless { it is JsonNull }
            textFrom(errorField ?: element)
        }.getOrNull()
        return when (response.code) {
            401, 403 -> "Nicht autorisiert (HTTP ${response.code}). Stimmt der API-Key?"
            404 -> "Endpunkt nicht gefunden (HTTP 404). Passt das eingestellte API-Format?"
            else -> buildString {
                append("Server-Fehler HTTP ${response.code}")
                if (!detail.isNullOrBlank()) append(": ").append(detail.take(300))
            }
        }
    }

    private fun friendlyIoMessage(e: IOException, settings: ServerSettings): String {
        val reason = e.message.orEmpty()
        return when {
            reason.contains("timeout", ignoreCase = true) ->
                "Zeitüberschreitung — ${settings.baseUrl} antwortet nicht."
            reason.contains("Unable to resolve host", ignoreCase = true) ->
                "Host „${settings.host}“ nicht auflösbar. Statt Name die IP-Adresse versuchen?"
            reason.contains("ECONNREFUSED", ignoreCase = true) ||
                reason.contains("Connection refused", ignoreCase = true) ->
                "Verbindung abgelehnt — lauscht auf Port ${settings.port} wirklich ein Server?"
            reason.contains("Canceled", ignoreCase = true) -> "Abgebrochen."
            else -> "Keine Verbindung zu ${settings.baseUrl} (${reason.ifBlank { "unbekannter Fehler" }})"
        }
    }

    private val Role.wireName: String
        get() = when (this) {
            Role.USER -> "user"
            Role.ASSISTANT -> "assistant"
        }

    private companion object {
        const val CONNECT_TIMEOUT_SECONDS = 8L
        const val PING_TIMEOUT_SECONDS = 4L
        const val DONE_MARKER = "[DONE]"
        const val MAX_JSON_DEPTH = 8
        val JSON_MEDIA_TYPE = "application/json; charset=utf-8".toMediaType()
        val TEXT_KEYS = listOf(
            "content", "delta", "token", "text", "reply", "response", "answer", "output", "message",
        )
        val CONTAINER_KEYS = listOf("choices", "data", "result")
    }
}
