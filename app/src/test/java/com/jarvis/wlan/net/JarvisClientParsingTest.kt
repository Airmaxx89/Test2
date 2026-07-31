package com.jarvis.wlan.net

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertThrows
import org.junit.Test

/**
 * Der Client muss die Antwortformate verschiedener Self-Hosting-Stacks
 * verdauen — diese Fälle sind draußen tatsächlich anzutreffen.
 */
class JarvisClientParsingTest {

    private val client = JarvisClient()

    @Test
    fun `openai delta chunk liefert content`() {
        val payload = """{"choices":[{"delta":{"content":"Hallo"},"index":0}]}"""
        assertEquals("Hallo", client.extractDelta(payload))
    }

    @Test
    fun `openai chunk ohne content liefert null`() {
        val payload = """{"choices":[{"delta":{"role":"assistant"},"finish_reason":null}]}"""
        assertNull(client.extractDelta(payload))
    }

    @Test
    fun `jarvis delta feld wird erkannt`() {
        assertEquals(" Welt", client.extractDelta("""{"delta":" Welt"}"""))
    }

    @Test
    fun `token feld wird erkannt`() {
        assertEquals("wie", client.extractDelta("""{"token":"wie"}"""))
    }

    @Test
    fun `reiner text ohne json wird durchgereicht`() {
        assertEquals("einfach Text", client.extractDelta("einfach Text"))
    }

    @Test
    fun `nicht streamende antwort mit reply feld`() {
        assertEquals("Guten Morgen", client.parseSingleReply("""{"reply":"Guten Morgen"}"""))
    }

    @Test
    fun `nicht streamende openai antwort`() {
        val body = """{"choices":[{"message":{"role":"assistant","content":"42"}}]}"""
        assertEquals("42", client.parseSingleReply(body))
    }

    @Test
    fun `ollama native antwort`() {
        val body = """{"message":{"role":"assistant","content":"Servus"},"done":true}"""
        assertEquals("Servus", client.parseSingleReply(body))
    }

    @Test
    fun `fehlerobjekt wird zur exception`() {
        val error = assertThrows(JarvisException::class.java) {
            client.parseSingleReply("""{"error":{"message":"model not found"}}""")
        }
        assertEquals(true, error.message?.contains("model not found"))
    }

    @Test
    fun `null error blockiert die antwort nicht`() {
        assertEquals("ok", client.parseSingleReply("""{"error":null,"reply":"ok"}"""))
    }

    @Test
    fun `leerer body bleibt leer`() {
        assertEquals("", client.parseSingleReply("   "))
    }
}
