package com.jarvis.wlan.data

import java.util.UUID

enum class Role { USER, ASSISTANT }

data class ChatMessage(
    val id: String = UUID.randomUUID().toString(),
    val role: Role,
    val text: String,
    val timestamp: Long = System.currentTimeMillis(),
    /** true, solange noch Deltas in diese Nachricht laufen. */
    val streaming: Boolean = false,
    /** Gesetzt, wenn die Antwort abgebrochen ist; [text] hält dann das Teilergebnis. */
    val error: String? = null,
)
