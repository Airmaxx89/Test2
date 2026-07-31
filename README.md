# Jarvis WLAN — Android-Client für dein eigenes Gehirn

Eine native Android-App (Kotlin + Jetpack Compose), mit der du dein
selbstgehostetes „Jarvis-Gehirn" über das heimische WLAN ansprichst — per Text
oder per Sprache. Die App redet ausschließlich mit deinem Server; es geht
nichts an fremde Dienste.

## Was drin ist

- **Chat mit Streaming** — Antworten erscheinen wortweise, während das Modell
  schreibt (Server-Sent Events), mit Stopp-Knopf.
- **Zwei API-Formate** — ein schlankes Eigenformat und OpenAI-kompatibel
  (`/v1/chat/completions`), damit Ollama, llama.cpp, LM Studio, vLLM oder
  LocalAI ohne Anpassung funktionieren.
- **Server-Suche im WLAN** — findet den Server per mDNS/Bonjour oder scannt das
  eigene /24-Subnetz nach offenen Ports und prüft die Treffer per Health-Check.
- **Spracheingabe und Vorlesen** — Diktat über die Android-Spracherkennung,
  Antworten optional per Text-to-Speech.
- **WLAN-Bindung** — Anfragen gehen gezielt über das WLAN-Interface. Ohne das
  routet Android in ein WLAN ohne Internetzugang stur über Mobilfunk, und das
  Heimnetz wäre unerreichbar. Optional lässt sich Mobilfunk ganz sperren.
- **Verbindungsstatus** — Health-Check mit Latenzanzeige, verständliche
  Fehlermeldungen statt roher Stacktraces.

## Schnellstart

### 1. Server starten

Zum Ausprobieren liegt ein Referenzserver bei (nur Standardbibliothek):

```bash
python3 server/jarvis_server.py --host 0.0.0.0 --port 8000
# optional, für die automatische Erkennung in der App:
pip install zeroconf
```

Er gibt beim Start die IP aus, die du in der App einträgst. Die eigentliche
Logik steckt in der Funktion `think()` — dort hängst du dein Gehirn ein.

### 2. App bauen

```bash
./gradlew assembleDebug
# APK: app/build/outputs/apk/debug/app-debug.apk
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

Voraussetzungen: JDK 17, Android SDK mit Plattform 35. Beim ersten Build lädt
Gradle das Android-Plugin und die AndroidX-Bibliotheken von Googles
Maven-Repository — der Rechner braucht also einmalig Internet.

### 3. Einrichten

Einstellungen öffnen → **Server suchen** (findet ihn im WLAN automatisch) oder
Host und Port von Hand eintragen → **Verbindung testen** → **Speichern**.

## Der API-Vertrag

### Modus „Jarvis (nativ)"

`GET /health` → `{"name": "Jarvis", "version": "1.0", "status": "ok"}`

`POST /chat`

```jsonc
{
  "message": "Wie ist das Wetter?",     // die aktuelle Frage
  "history": [                          // bisheriger Verlauf, ältestes zuerst
    {"role": "user", "content": "Hallo"},
    {"role": "assistant", "content": "Guten Tag!"}
  ],
  "stream": true,                       // SSE gewünscht?
  "system_prompt": "…",                 // nur wenn in der App gesetzt
  "model": "jarvis-local"
}
```

Antwort ohne Streaming — JSON mit dem Text in einem dieser Felder: `reply`,
`response`, `text`, `content`, `answer`, `output` oder `message`:

```json
{"reply": "Draußen sind es 18 Grad."}
```

Antwort mit Streaming — `Content-Type: text/event-stream`, ein Delta pro Event,
Abschluss mit `[DONE]`:

```
data: {"delta": "Draußen "}

data: {"delta": "sind es 18 Grad."}

data: [DONE]
```

Statt `delta` gehen auch `token`, `text` oder `content`; reiner Text ohne JSON
wird ebenfalls akzeptiert. Ein `{"error": …}` im Body wird als Fehler angezeigt.

Wichtig für eigene Server: Beim Streaming **kein** `Connection: keep-alive`
ohne `Content-Length` senden — sonst erkennt der Client das Ende nicht und
wartet bis zum Zeitlimit.

### Modus „OpenAI-kompatibel"

Die App spricht `POST /v1/chat/completions` mit `messages`, `model` und
`stream` und liest `choices[].delta.content` bzw. `choices[].message.content`.
`GET /v1/models` dient als Health-Check. Ein gesetzter API-Key geht als
`Authorization: Bearer …` mit.

Für Ollama:

```bash
OLLAMA_HOST=0.0.0.0:11434 ollama serve
```

In der App: Port `11434`, Format **OpenAI-kompatibel**, Modell z. B. `llama3`.

## Aufbau

```
app/src/main/java/com/jarvis/wlan/
├── data/           ServerSettings, ChatMessage, DataStore-Persistenz
├── net/            JarvisClient (HTTP/SSE), ServerDiscovery (mDNS + Portscan)
├── speech/         VoiceInput (Diktat), Speaker (Vorlesen)
├── ui/chat/        Chat-Screen und ViewModel
├── ui/settings/    Einstellungen
├── ui/discovery/   Server-Suche
└── util/           NetworkStatus (WLAN-Erkennung, Interface-Bindung)
```

## Tests

```bash
./gradlew test
```

19 JVM-Tests decken den Netzwerkteil ab: das Parsen der Antwortformate
(OpenAI, Ollama, Eigenformat, Fehlerobjekte) und den kompletten Anfrageweg
gegen einen MockWebServer — Streaming, Historie, Authentifizierung,
Fehlercodes.

## Sicherheit

Die App erlaubt unverschlüsseltes HTTP, weil Server im Heimnetz selten ein
gültiges Zertifikat haben (`res/xml/network_security_config.xml`). Im WLAN ist
das üblich; über unsichere Netze solltest du den Server nicht erreichbar machen.
Wenn dein Server HTTPS spricht, stell in der App das Protokoll auf `https` um —
selbst signierte Zertifikate greifen, sobald die CA im Gerät installiert ist.
Der API-Key liegt in DataStore und ist von Cloud-Backups ausgenommen.

## Bekannte Grenzen

- Der Gesprächsverlauf lebt im Arbeitsspeicher: Wird die App vom System
  beendet, ist er weg. Die Einstellungen bleiben.
- Der Subnetz-Scan deckt nur das eigene /24 ab und prüft eine feste Portliste
  (8000, 8080, 5000, 11434, 1234, 3000).
- Die mDNS-Suche braucht einen Server, der sich ankündigt, und ein WLAN, das
  Multicast nicht filtert (manche Gäste-/Mesh-Netze tun das).
