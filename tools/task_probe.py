#!/usr/bin/env python3
"""
Minimal localhost probe for observing Chatterfly task submission shape.

Security properties:
- binds only to 127.0.0.1
- redacts token / authorization / api_key / apikey before logging
- does not validate, replay, forge, or reuse authentication artifacts

Use only when DeepSeek Harness is NOT already listening on the selected port.
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any


SENSITIVE_KEYS = {"token", "authorization", "api_key", "apikey"}


def redact(value: Any) -> Any:
    if isinstance(value, dict):
        out = {}
        for key, item in value.items():
            if str(key).lower() in SENSITIVE_KEYS:
                out[key] = "<redacted>"
            else:
                out[key] = redact(item)
        return out
    if isinstance(value, list):
        return [redact(item) for item in value]
    return value


def now_iso() -> str:
    return datetime.now(timezone.utc).astimezone().isoformat(timespec="milliseconds")


class Handler(BaseHTTPRequestHandler):
    server_version = "ChatterflyResearchProbe/1.0"

    def _log_record(self, body: Any) -> None:
        record = {
            "ts": now_iso(),
            "method": self.command,
            "path": self.path,
            "client": f"{self.client_address[0]}:{self.client_address[1]}",
            "headers": {
                "Host": self.headers.get("Host", ""),
                "Content-Type": self.headers.get("Content-Type", ""),
                "Content-Length": self.headers.get("Content-Length", ""),
                "Accept": self.headers.get("Accept", ""),
                "Last-Event-ID": self.headers.get("Last-Event-ID", ""),
            },
            "body": redact(body),
        }
        with self.server.log_path.open("a", encoding="utf-8") as f:
            f.write(json.dumps(record, ensure_ascii=False) + "\n")

    def _send_json(self, status: int, payload: dict[str, Any]) -> None:
        raw = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def do_GET(self) -> None:
        self._log_record(None)
        if self.path == "/chatterfly/v1/health":
            self._send_json(200, {"ok": True, "probe": True})
            return
        self._send_json(404, {"error": "not-found"})

    def do_POST(self) -> None:
        length = int(self.headers.get("Content-Length") or "0")
        raw = self.rfile.read(length)
        try:
            body = json.loads(raw.decode("utf-8"))
        except Exception:
            body = {"raw_bytes": len(raw)}

        self._log_record(body)

        # Probe-only: do not pretend to be the full Chatterfly server.
        self._send_json(404, {"error": "probe-only"})

    def log_message(self, fmt: str, *args: Any) -> None:
        print(f"[{now_iso()}] {self.client_address[0]} {fmt % args}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=3080)
    parser.add_argument("--log", type=Path, default=Path("probe-requests.jsonl"))
    args = parser.parse_args()

    server = ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
    server.log_path = args.log.resolve()

    print(f"Listening on http://127.0.0.1:{args.port}")
    print(f"Sanitized log: {server.log_path}")
    print("Stop with Ctrl+C.")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
