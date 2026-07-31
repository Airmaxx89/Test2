package com.jarvis.wlan.net

import com.jarvis.wlan.data.ApiMode
import com.jarvis.wlan.data.ChatMessage
import com.jarvis.wlan.data.Role
import com.jarvis.wlan.data.ServerSettings
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.test.runTest
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/** Prüft den kompletten Anfrage-/Antwortweg gegen einen echten HTTP-Server. */
class JarvisClientStreamingTest {

    private lateinit var server: MockWebServer
    private val client = JarvisClient()

    @Before
    fun setUp() {
        server = MockWebServer()
        server.start()
    }

    @After
    fun tearDown() {
        server.shutdown()
    }

    private fun settings(
        mode: ApiMode = ApiMode.JARVIS,
        streaming: Boolean = true,
        apiKey: String = "",
    ) = ServerSettings(
        scheme = "http",
        host = server.hostName,
        port = server.port,
        apiMode = mode,
        streaming = streaming,
        apiKey = apiKey,
        timeoutSeconds = 10,
    )

    private fun frage(text: String = "Wie spät ist es?") =
        listOf(ChatMessage(role = Role.USER, text = text))

    @Test
    fun `sse deltas kommen einzeln an`() = runTest {
        server.enqueue(
            MockResponse()
                .setHeader("Content-Type", "text/event-stream")
                .setBody(
                    "data: {\"delta\":\"Guten \"}\n\n" +
                        "data: {\"delta\":\"Morgen\"}\n\n" +
                        "data: [DONE]\n\n",
                ),
        )

        val deltas = client.chat(settings(), frage()).toList()

        assertEquals(listOf("Guten ", "Morgen"), deltas)
        val recorded = server.takeRequest()
        assertEquals("/chat", recorded.path)
        assertTrue(recorded.body.readUtf8().contains("\"message\":\"Wie spät ist es?\""))
    }

    @Test
    fun `openai stream wird gelesen und richtig adressiert`() = runTest {
        server.enqueue(
            MockResponse()
                .setHeader("Content-Type", "text/event-stream")
                .setBody(
                    "data: {\"choices\":[{\"delta\":{\"role\":\"assistant\"}}]}\n\n" +
                        "data: {\"choices\":[{\"delta\":{\"content\":\"42\"}}]}\n\n" +
                        "data: [DONE]\n\n",
                ),
        )

        val deltas = client.chat(settings(mode = ApiMode.OPENAI, apiKey = "geheim"), frage()).toList()

        assertEquals(listOf("42"), deltas)
        val recorded = server.takeRequest()
        assertEquals("/v1/chat/completions", recorded.path)
        assertEquals("Bearer geheim", recorded.getHeader("Authorization"))
        assertTrue(recorded.body.readUtf8().contains("\"messages\""))
    }

    @Test
    fun `mehrzeiliges datenfeld wird zusammengefuegt`() = runTest {
        server.enqueue(
            MockResponse()
                .setHeader("Content-Type", "text/event-stream")
                .setBody("data: Zeile eins\ndata: Zeile zwei\n\n"),
        )

        val deltas = client.chat(settings(), frage()).toList()

        assertEquals(listOf("Zeile eins\nZeile zwei"), deltas)
    }

    @Test
    fun `antwort ohne streaming kommt als ein block`() = runTest {
        server.enqueue(
            MockResponse()
                .setHeader("Content-Type", "application/json")
                .setBody("""{"reply":"Es ist kurz nach drei."}"""),
        )

        val deltas = client.chat(settings(streaming = false), frage()).toList()

        assertEquals(listOf("Es ist kurz nach drei."), deltas)
    }

    @Test
    fun `serverfehler wird zur jarvis exception`() = runTest {
        server.enqueue(MockResponse().setResponseCode(500).setBody("""{"error":"Modell abgestürzt"}"""))

        val error = runCatching { client.chat(settings(), frage()).toList() }.exceptionOrNull()

        assertTrue(error is JarvisException)
        assertTrue(error!!.message!!.contains("500"))
        assertTrue(error.message!!.contains("Modell abgestürzt"))
    }

    @Test
    fun `fehlender api key liefert klare meldung`() = runTest {
        server.enqueue(MockResponse().setResponseCode(401))

        val error = runCatching { client.chat(settings(), frage()).toList() }.exceptionOrNull()

        assertTrue(error!!.message!!.contains("API-Key"))
    }

    @Test
    fun `historie wandert vollstaendig in die anfrage`() = runTest {
        server.enqueue(
            MockResponse()
                .setHeader("Content-Type", "application/json")
                .setBody("""{"reply":"ok"}"""),
        )
        val verlauf = listOf(
            ChatMessage(role = Role.USER, text = "Erste Frage"),
            ChatMessage(role = Role.ASSISTANT, text = "Erste Antwort"),
            ChatMessage(role = Role.USER, text = "Zweite Frage"),
        )

        client.chat(settings(streaming = false), verlauf).toList()

        val body = server.takeRequest().body.readUtf8()
        // Die aktuelle Frage steht in "message", der Rest in "history".
        assertTrue(body.contains("\"message\":\"Zweite Frage\""))
        assertTrue(body.contains("Erste Antwort"))
    }

    @Test
    fun `health check meldet erreichbarkeit`() = runTest {
        server.enqueue(
            MockResponse()
                .setHeader("Content-Type", "application/json")
                .setBody("""{"name":"Jarvis","version":"1.0","status":"ok"}"""),
        )

        val info = client.ping(settings())

        assertTrue(info.reachable)
        assertEquals("Jarvis 1.0", info.detail)
        assertEquals("/health", server.takeRequest().path)
    }
}
