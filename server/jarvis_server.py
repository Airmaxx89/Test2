#!/usr/bin/env python3
"""Referenz-Server für die Jarvis-WLAN-App.

Zeigt den Vertrag, den die App im Modus "Jarvis (nativ)" erwartet, und dient
als Testgegenstelle. Nur Standardbibliothek — `python3 jarvis_server.py` genügt.
Ist das Paket `zeroconf` installiert, meldet sich der Server zusätzlich per
mDNS als `_jarvis._tcp` an und die App findet ihn ohne IP-Eingabe.

Die eigentliche Intelligenz steckt in `think()` — dort hängst du dein Gehirn ein.

    python3 jarvis_server.py --host 0.0.0.0 --port 8000

Endpunkte:
    GET  /health  -> {"name": ..., "version": ..., "status": "ok"}
    POST /chat    -> Antwort als JSON oder, bei "stream": true, als SSE
"""

from __future__ import annotations

import argparse
import json
import socket
import sys
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Iterator

NAME = "Jarvis"
VERSION = "1.0"
API_KEY: str | None = None  # per --api-key setzen; None = keine Prüfung


def think(message: str, history: list[dict], system_prompt: str) -> Iterator[str]:
    """Erzeugt die Antwort — hier dein Gehirn einhängen.

    Muss Textstücke liefern (yield). Für ein nicht-streamendes Modell einfach
    einmal das Gesamtergebnis yielden.
    """
    reply = (
        f"Ich habe verstanden: „{message}“. "
        f"Bisher kenne ich {len(history)} vorherige Nachrichten."
    )
    if system_prompt:
        reply += f" (System-Prompt aktiv: {len(system_prompt)} Zeichen)"

    # Wortweise ausgeben, damit sich das Streaming in der App beobachten lässt.
    for word in reply.split(" "):
        yield word + " "
        time.sleep(0.04)


class JarvisHandler(BaseHTTPRequestHandler):
    server_version = f"{NAME}/{VERSION}"

    def do_GET(self) -> None:  # noqa: N802 (von BaseHTTPRequestHandler vorgegeben)
        if self.path.rstrip("/") in ("/health", ""):
            self._send_json(200, {"name": NAME, "version": VERSION, "status": "ok"})
        else:
            self._send_json(404, {"error": "unbekannter Endpunkt"})

    def do_POST(self) -> None:  # noqa: N802
        if self.path.rstrip("/") != "/chat":
            self._send_json(404, {"error": "unbekannter Endpunkt"})
            return

        if not self._authorized():
            self._send_json(401, {"error": "ungültiger API-Key"})
            return

        try:
            payload = self._read_json()
        except ValueError as exc:
            self._send_json(400, {"error": f"ungültiges JSON: {exc}"})
            return

        message = str(payload.get("message", "")).strip()
        if not message:
            self._send_json(400, {"error": "Feld 'message' fehlt"})
            return

        history = payload.get("history") or []
        system_prompt = str(payload.get("system_prompt", ""))
        wants_stream = bool(payload.get("stream", False))

        if wants_stream:
            self._stream_reply(message, history, system_prompt)
        else:
            reply = "".join(think(message, history, system_prompt))
            self._send_json(200, {"reply": reply})

    def _stream_reply(self, message: str, history: list, system_prompt: str) -> None:
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream; charset=utf-8")
        self.send_header("Cache-Control", "no-cache")
        # Ohne Content-Length erkennt der Client das Ende nur am Verbindungsabbau.
        # "keep-alive" würde die App nach dem letzten Delta ewig warten lassen.
        self.send_header("Connection", "close")
        # Wichtig für Zwischenpuffer (z. B. nginx davor).
        self.send_header("X-Accel-Buffering", "no")
        self.end_headers()

        try:
            for chunk in think(message, history, system_prompt):
                data = json.dumps({"delta": chunk}, ensure_ascii=False)
                self.wfile.write(f"data: {data}\n\n".encode("utf-8"))
                self.wfile.flush()
            self.wfile.write(b"data: [DONE]\n\n")
            self.wfile.flush()
        except (BrokenPipeError, ConnectionResetError):
            # Die App hat den Stream abgebrochen — völlig normal.
            pass

    def _authorized(self) -> bool:
        if not API_KEY:
            return True
        header = self.headers.get("Authorization", "")
        return header == f"Bearer {API_KEY}"

    def _read_json(self) -> dict:
        length = int(self.headers.get("Content-Length") or 0)
        if length <= 0:
            return {}
        raw = self.rfile.read(length)
        return json.loads(raw.decode("utf-8"))

    def _send_json(self, status: int, body: dict) -> None:
        data = json.dumps(body, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, fmt: str, *args) -> None:
        sys.stderr.write("%s - %s\n" % (self.address_string(), fmt % args))


def local_ip() -> str:
    """Die IP, unter der das Handy den Server im WLAN erreicht."""
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as probe:
        try:
            probe.connect(("192.168.1.1", 80))  # es fließt kein Paket
            return probe.getsockname()[0]
        except OSError:
            return "127.0.0.1"


def advertise(port: int):
    """Meldet den Dienst per mDNS an, sofern `zeroconf` installiert ist."""
    try:
        from zeroconf import ServiceInfo, Zeroconf
    except ImportError:
        print("Hinweis: 'pip install zeroconf' aktiviert die automatische "
              "Erkennung in der App.")
        return None

    ip = local_ip()
    info = ServiceInfo(
        "_jarvis._tcp.local.",
        f"{NAME}._jarvis._tcp.local.",
        addresses=[socket.inet_aton(ip)],
        port=port,
        properties={"version": VERSION, "api": "jarvis"},
        server=f"jarvis-{ip.replace('.', '-')}.local.",
    )
    zeroconf = Zeroconf()
    zeroconf.register_service(info)
    print(f"mDNS: als _jarvis._tcp auf {ip}:{port} angekündigt")
    return zeroconf, info


def main() -> None:
    global API_KEY

    parser = argparse.ArgumentParser(description="Jarvis-Referenzserver")
    parser.add_argument("--host", default="0.0.0.0", help="Bind-Adresse (Standard: alle)")
    parser.add_argument("--port", type=int, default=8000, help="Port (Standard: 8000)")
    parser.add_argument("--api-key", default=None, help="Optionaler Bearer-Token")
    args = parser.parse_args()

    API_KEY = args.api_key

    handle = advertise(args.port)
    httpd = ThreadingHTTPServer((args.host, args.port), JarvisHandler)
    print(f"{NAME} {VERSION} lauscht auf http://{local_ip()}:{args.port}")
    print("In der App eintragen: Host = obige IP, Port = "
          f"{args.port}, API-Format = Jarvis (nativ)")

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nBeendet.")
    finally:
        httpd.server_close()
        if handle:
            zeroconf, info = handle
            zeroconf.unregister_service(info)
            zeroconf.close()


if __name__ == "__main__":
    main()
