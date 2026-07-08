"""Tiny local backend for the Slowloris gateway lab.

This service is intentionally small. It is only a target behind Nginx in a
local, authorized lab.
"""

from __future__ import annotations

import argparse
import json
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


class LabHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    server_version = "LocalBackend/1.0"

    def _send_json(self, status: int, payload: dict) -> None:
        body = json.dumps(payload, ensure_ascii=False, indent=2).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:
        if self.path.startswith("/health"):
            self._send_json(
                200,
                {
                    "status": "ok",
                    "service": "local-backend",
                    "timestamp": time.time(),
                },
            )
            return

        self._send_json(
            200,
            {
                "message": "Hello from the local backend behind Nginx.",
                "path": self.path,
                "client": self.client_address[0],
                "timestamp": time.time(),
            },
        )

    def do_POST(self) -> None:
        length_header = self.headers.get("Content-Length", "0")
        try:
            length = int(length_header)
        except ValueError:
            self._send_json(400, {"error": "invalid Content-Length"})
            return

        if length > 1024 * 1024:
            self._send_json(413, {"error": "request body too large for lab"})
            return

        body = self.rfile.read(length) if length > 0 else b""
        self._send_json(
            200,
            {
                "received_bytes": len(body),
                "body_preview": body[:200].decode("utf-8", errors="replace"),
                "timestamp": time.time(),
            },
        )

    def log_message(self, fmt: str, *args) -> None:
        print(
            "%s - - [%s] %s"
            % (self.client_address[0], self.log_date_time_string(), fmt % args),
            flush=True,
        )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run a tiny local backend.")
    parser.add_argument("--host", default="127.0.0.1", help="bind host")
    parser.add_argument("--port", default=18080, type=int, help="bind port")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    server = ThreadingHTTPServer((args.host, args.port), LabHandler)
    print(f"Local backend listening on http://{args.host}:{args.port}", flush=True)
    print("Press Ctrl+C to stop.", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping backend...", flush=True)
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
