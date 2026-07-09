"""Tiny local backend for the Slowloris gateway lab.

This service is intentionally small. It is only a target behind Nginx in a
local, authorized lab.

展示说明：
- 这个文件模拟“真实业务后端”，监听 127.0.0.1:18080。
- 现场讲架构时，可以把它理解为 Nginx 网关后面的服务。
- Slowloris 攻击工具不会直接打这个后端，而是先打 Nginx 的 8080 端口。
- 如果请求头没有完整到达 Nginx，后端甚至可能收不到完整请求，这正是慢速攻击卡在入口层的原因。
"""

from __future__ import annotations

import argparse
import json
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


class LabHandler(BaseHTTPRequestHandler):
    """处理本地实验请求的 HTTP Handler。

    BaseHTTPRequestHandler 是 Python 标准库提供的简单 HTTP 处理基类。
    在本实验里，它只承担两个职责：
    1. 提供 /health，让我们验证“正常请求是否还能通过 Nginx 到达后端”。
    2. 返回一个简单 JSON，用来证明 Nginx 确实把请求转发到了后端。
    """

    # 使用 HTTP/1.1 是为了贴近 Nginx 反向代理和连接复用的常见场景。
    protocol_version = "HTTP/1.1"

    # 自定义 server_version 方便看日志时识别这是本地实验后端。
    server_version = "LocalBackend/1.0"

    def _send_json(self, status: int, payload: dict) -> None:
        """把 Python 字典统一包装成 JSON 响应。"""

        body = json.dumps(payload, ensure_ascii=False, indent=2).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")

        # Content-Length 对 HTTP/1.1 很重要：客户端知道响应体有多长，连接状态也更清楚。
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:
        """处理 GET 请求。

        展示时重点看 /health：
        - 基线攻击中 /health 仍然 200，说明本轮低强度实验没有把服务打挂。
        - 加固后 /health 仍然 200，说明防御配置没有影响正常健康检查。
        """

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

        # 非 /health 路径返回普通业务响应，用来说明请求已经穿过 Nginx 到达后端。
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
        """处理 POST 请求。

        本次主要实现 Slowloris（慢速请求头攻击），不是 Slow POST（慢速请求体攻击）。
        这里保留 POST 处理，是为了让后续扩展 Slow POST 时有一个能接收请求体的后端。
        """

        length_header = self.headers.get("Content-Length", "0")
        try:
            length = int(length_header)
        except ValueError:
            self._send_json(400, {"error": "invalid Content-Length"})
            return

        # 限制请求体大小，避免本地实验误传大文件导致机器负载过高。
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
        """把后端访问日志打印到控制台。

        如果 Nginx 收到的是完整正常请求，后端会打印日志。
        如果 Slowloris 一直不发完请求头，请求可能卡在 Nginx 入口层，后端就不一定能看到它。
        """

        print(
            "%s - - [%s] %s"
            % (self.client_address[0], self.log_date_time_string(), fmt % args),
            flush=True,
        )


def parse_args() -> argparse.Namespace:
    """解析启动参数。

    默认监听 127.0.0.1:18080。展示时可以说明：
    - 18080 是后端端口。
    - 8080 是 Nginx 网关端口。
    - 攻击工具打 8080，不直接打 18080。
    """

    parser = argparse.ArgumentParser(description="Run a tiny local backend.")
    parser.add_argument("--host", default="127.0.0.1", help="bind host")
    parser.add_argument("--port", default=18080, type=int, help="bind port")
    return parser.parse_args()


def main() -> None:
    """启动本地后端服务。

    ThreadingHTTPServer 支持多线程处理请求，足够用于本地培训实验。
    真正的网关防护逻辑不在这里，而在 Nginx 配置中。
    """

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
