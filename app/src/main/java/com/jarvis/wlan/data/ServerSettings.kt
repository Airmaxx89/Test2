package com.jarvis.wlan.data

/**
 * Wie der Server seine Chat-API anbietet.
 *
 * [JARVIS] ist das schlanke Eigenformat (siehe README / server/jarvis_server.py),
 * [OPENAI] passt auf alles, was `/v1/chat/completions` spricht — llama.cpp,
 * Ollama (mit OpenAI-Endpoint), LM Studio, vLLM, LocalAI …
 */
enum class ApiMode {
    JARVIS,
    OPENAI,
    ;

    companion object {
        fun fromName(name: String?): ApiMode =
            entries.firstOrNull { it.name == name } ?: JARVIS
    }
}

data class ServerSettings(
    val scheme: String = DEFAULT_SCHEME,
    val host: String = "",
    val port: Int = DEFAULT_PORT,
    val apiMode: ApiMode = ApiMode.JARVIS,
    val model: String = "jarvis-local",
    val apiKey: String = "",
    val streaming: Boolean = true,
    val speakReplies: Boolean = false,
    val wifiOnly: Boolean = true,
    val timeoutSeconds: Int = DEFAULT_TIMEOUT_SECONDS,
    val systemPrompt: String = "",
) {
    val isConfigured: Boolean get() = host.isNotBlank()

    val baseUrl: String get() = "$scheme://${host.trim().trimEnd('/')}:$port"

    /** [path] beginnt mit "/". */
    fun url(path: String): String = baseUrl + path

    val chatPath: String
        get() = when (apiMode) {
            ApiMode.JARVIS -> "/chat"
            ApiMode.OPENAI -> "/v1/chat/completions"
        }

    val healthPath: String
        get() = when (apiMode) {
            ApiMode.JARVIS -> "/health"
            ApiMode.OPENAI -> "/v1/models"
        }

    companion object {
        const val DEFAULT_SCHEME = "http"
        const val DEFAULT_PORT = 8000
        const val DEFAULT_TIMEOUT_SECONDS = 90
        val SCHEMES = listOf("http", "https")
    }
}
