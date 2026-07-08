# 02-approach-and-tech-selection

阶段：第三阶段 - 确定技术选型与产出方案  
主线 agent：agent-main（主线流程代理，负责阶段推进和汇总）  
生成时间：2026-07-08  
输入文件：`00-raw-materials-analysis.md`、`01-requirements-and-questions.md`  
状态：已完成第三阶段方案，等待用户确认后再进入第四阶段

## 1. 本阶段确认来源

本阶段已读取第一阶段和第二阶段文件，并读取到用户在 `01-requirements-and-questions.md` 末尾补充的回答。确认结果如下：

| 项目 | 用户确认/本阶段采用方案 |
| --- | --- |
| 攻击类型 | Slowloris（慢速 HTTP 请求头攻击，HTTP 是 HyperText Transfer Protocol，超文本传输协议）。 |
| 攻击工具语言 | Python（解释型编程语言）。 |
| Nginx 部署方式 | 仅在 Windows（Microsoft Windows，微软桌面操作系统）本机部署，不使用 Docker（开源容器化平台）。 |
| 报告格式 | Markdown（轻量标记语言），产物为 `03-delivery.md`。 |
| 选做项 | 暂时不做资源曲线和完整指标采集，但预留接口；必做完成后再考虑补充。 |
| 安全边界 | 只针对本地授权环境运行。 |
| 引用资料 | 可以引用课件原话，也可以引用官方文档资料。 |
| README | 需要源码 README（Read Me，项目说明文件）。 |
| 防御范围 | 只使用 Nginx 原生配置，不引入操作系统防火墙或第三方防护组件。 |
| 配置文件 | 拆分为防御前基线配置和防御后加固配置。 |
| 攻击工具安全限制 | 保留低强度默认值和本地目标限制。 |
| 个人理解 | 报告需要包含“我的选择理由/我的理解”段落。 |
| 平台支持 | 只需支持 Windows 本机。 |
| 其他事项 | 按第二阶段推荐方案执行。 |

## 2. 当前环境检查结果

| 检查项 | 结果 | 对方案的影响 |
| --- | --- | --- |
| Python | 已发现可用的 Python 3.12.13。 | 可使用 Python 标准库编写后端服务、Slowloris 攻击模拟工具和辅助脚本。 |
| Docker | 当前命令行未发现 `docker` 命令。 | 与用户确认一致，本次不采用 Docker 方案。 |
| Docker Compose | 当前命令行未发现 `docker compose` 命令。 | 不采用容器编排方案。 |
| Nginx | 当前命令行未发现 `nginx` 命令。 | 第四阶段可以先生成配置和启动脚本，但实际运行前需要本机已有 Nginx Windows 版，或用户提供 `nginx.exe` 所在目录。 |
| Git（版本控制工具） | 当前仓库因沙箱用户与目录所有者不一致，`git status` 触发 safe.directory 限制。 | 不影响阶段文件生成；后续若需要 Git 状态或提交，需要用户确认是否添加安全目录例外。 |

本阶段结论：技术方案采用“Windows 本机 Nginx + Python 后端 + Python Slowloris 工具”。Nginx 当前不在命令行路径中，因此第四阶段应把 Nginx 路径做成参数或环境变量，不硬编码本机绝对路径。

## 3. 总体产出方案

后续第四阶段建议生成以下源码和文档结构：

```text
<TaskDir>/
  README.md
  03-delivery.md
  backend/
    app.py
  attack/
    slowloris.py
  nginx/
    conf/
      nginx-baseline.conf
      nginx-hardened.conf
    logs/
      .gitkeep
    temp/
      .gitkeep
  scripts/
    check-env.ps1
    start-backend.ps1
    start-nginx.ps1
    stop-nginx.ps1
    run-baseline-test.ps1
    run-hardened-test.ps1
    collect-metrics.ps1
  observability/
    metrics-template.csv
    notes.md
```

说明：

- `README.md` 面向作业复现，写清目录结构、运行前提、安全边界、运行步骤和常见问题。
- `03-delivery.md` 是正式短报告，包含攻击现象、防御原理、防御配置、验证结果、我的选择理由/我的理解、可观测性接口预留。
- `backend/app.py` 是本地后端服务，提供 `/`、`/health`、`/echo` 等简单端点。
- `attack/slowloris.py` 是攻击模拟工具，只允许默认访问本地回环地址。
- `nginx-baseline.conf` 是默认/基线配置，用于观察未加固时的慢速连接占用。
- `nginx-hardened.conf` 是加固配置，仅使用 Nginx 原生指令。
- `collect-metrics.ps1` 和 `observability/` 只作为接口预留，不把资源曲线列为第四阶段必做。

## 4. 技术选型

| 模块 | 选型 | 理由 | 风险/约束 |
| --- | --- | --- | --- |
| 网关 | Nginx Windows 版 | 符合作业要求，能够体现入口连接管理、请求头读取超时和连接限制。 | 当前未在命令行路径中发现 `nginx.exe`，需要用户本机安装或指定目录。 |
| 后端服务 | Python 标准库 `http.server` + 自定义 `BaseHTTPRequestHandler` | 无需外部依赖，适合 Windows 本机运行，代码足够短，便于理解。 | 功能简单，只用于实验，不代表生产后端。 |
| 攻击工具 | Python `socket` 标准库 | Slowloris 本质是打开多个 TCP（Transmission Control Protocol，传输控制协议）连接并缓慢发送未完成请求头，标准库即可实现。 | 必须限制目标为本地授权环境，避免被误用于未授权目标。 |
| 启动脚本 | PowerShell（Windows 自动化脚本） | 用户确认只需支持 Windows，本机脚本更直观。 | PowerShell 执行策略可能限制脚本运行，需要 README 中给出说明。 |
| 报告 | Markdown | 适合放配置块、命令、实验记录和 Mermaid（文本化图表语法）架构图。 | 若后续需要 Word/PDF，需要另行转换。 |
| 防御配置 | Nginx 原生配置 | 用户明确要求只使用 Nginx 原生配置。 | 不能使用系统防火墙、WAF 插件或第三方流量清洗能力。 |
| 可观测接口 | PowerShell + CSV（Comma-Separated Values，逗号分隔值）模板 | 为后续资源曲线和指标清单预留数据结构。 | 第四阶段先不保证生成真实资源曲线。 |

## 5. 攻击方案设计

### 5.1 Slowloris 攻击模拟逻辑

Slowloris 的关键不是高吞吐，而是“慢”和“悬而未决”：

1. 攻击工具与 Nginx 建立多个 TCP 连接。
2. 每个连接发送请求行和少量 HTTP 请求头，但不发送空行，因此请求头没有结束。
3. 工具定期向每个连接补发一小段头部，例如 `X-a: <random>`，让连接看起来仍然活跃。
4. Nginx 在默认 `client_header_timeout` 较长的情况下，需要保留这些连接并等待完整请求头。
5. 当慢连接数量足够多时，入口层连接资源被占用，正常请求可能变慢、被拒绝或出现连接等待。

### 5.2 攻击工具安全设计

`attack/slowloris.py` 建议采用以下安全策略：

| 策略 | 设计 |
| --- | --- |
| 默认目标 | `127.0.0.1:8080`。 |
| 目标限制 | 只允许 `127.0.0.1`、`localhost`、`::1`。 |
| 默认强度 | 低强度，例如 30 个连接、10 秒补发一次、持续 60 秒。 |
| 参数保护 | 如果用户传入非本地目标，程序直接拒绝运行。 |
| 输出说明 | 启动时打印“仅用于本地授权实验”的提示。 |
| 退出处理 | `Ctrl+C` 或持续时间结束后关闭所有 socket（套接字，网络连接编程接口）。 |

### 5.3 建议参数

| 参数 | 默认值 | 含义 |
| --- | --- | --- |
| `--host` | `127.0.0.1` | 目标主机，仅允许本地地址。 |
| `--port` | `8080` | Nginx 监听端口。 |
| `--connections` | `30` | 慢连接数量，默认低强度。 |
| `--interval` | `10` | 每隔多少秒补发一小段请求头。 |
| `--duration` | `60` | 攻击模拟持续时间。 |
| `--path` | `/` | 请求路径。 |

## 6. Nginx 配置方案

### 6.1 基线配置

`nginx-baseline.conf` 目标是尽量接近默认行为，只做本地反向代理必要配置：

- 监听 `127.0.0.1:8080`。
- 代理到本地后端 `127.0.0.1:18080`。
- 保留常规访问日志和错误日志。
- 不配置专门的慢速攻击防护指令。

基线用于证明：当请求头一直不完整时，入口连接会被保留，正常请求可能受到影响。

### 6.2 加固配置

`nginx-hardened.conf` 只使用 Nginx 原生配置，重点控制 Slowloris 的两个关键点：等待请求头的时间和单个来源可占用的连接数。

建议方向：

| 指令 | 作用 | 与 Slowloris 的关系 |
| --- | --- | --- |
| `client_header_timeout` | 设置读取客户端请求头的超时时间。 | Slowloris 依赖长时间不发完整请求头；缩短该值可以更快释放慢连接。 |
| `keepalive_timeout` | 设置空闲 keep-alive（长连接保持机制）连接保留时间。 | 降低空闲连接长期占用入口资源的机会。 |
| `limit_conn_zone` + `limit_conn` | 按客户端 IP（Internet Protocol，互联网协议）限制并发连接数。 | 防止单一本地来源打开过多慢连接。 |
| `limit_conn_status` | 设置连接数超限时返回状态码。 | 便于在日志和测试中识别防护生效。 |
| `reset_timedout_connection` | 对超时连接直接复位。 | 有助于更快清理已超时连接。 |
| `client_body_timeout` | 设置读取请求体的超时时间。 | 本次主攻 Slowloris，不是 Slow POST，但保留合理值可体现同类慢速攻击防御思路。 |

官方依据：

- Nginx 官方核心模块文档说明 `client_header_timeout` 用于读取客户端请求头超时，客户端未在时间内发送完整请求头时会返回 408（Request Time-out，请求超时）错误。
- Nginx 官方核心模块文档说明 `client_body_timeout` 用于读取请求体两次读操作之间的超时，超时会返回 408。
- Nginx 官方核心模块文档说明 `keepalive_timeout` 控制服务端保留 keep-alive 客户端连接的时间。
- Nginx 官方 `limit_conn` 模块文档说明可基于共享内存区和 key 限制连接数，常用 `$binary_remote_addr` 作为客户端 IP key。
- Nginx 官方 `limit_req` 模块文档说明可按 key 限制请求处理速率；本次不作为 Slowloris 主防线，但可在指标扩展中说明它更适合请求速率类场景。

参考链接：

- [Nginx core module: client_header_timeout/client_body_timeout/keepalive_timeout](https://nginx.org/en/docs/http/ngx_http_core_module.html)
- [Nginx limit_conn module](https://nginx.org/en/docs/http/ngx_http_limit_conn_module.html)
- [Nginx limit_req module](https://nginx.org/en/docs/http/ngx_http_limit_req_module.html)

## 7. 验证方法

### 7.1 必做验证

| 步骤 | 验证内容 | 通过标准 |
| --- | --- | --- |
| V1 | 后端服务可直接访问。 | 访问 `http://127.0.0.1:18080/health` 返回健康状态。 |
| V2 | Nginx 基线配置可启动。 | 访问 `http://127.0.0.1:8080/health` 能通过 Nginx 转发到后端。 |
| V3 | Slowloris 工具可在本地运行。 | 工具能够建立多个本地慢连接，并输出连接状态。 |
| V4 | 基线下观察攻击现象。 | 日志、连接状态或正常请求表现显示慢连接占用入口资源。 |
| V5 | 加固配置可启动。 | Nginx 重新加载或重启后使用 `nginx-hardened.conf`。 |
| V6 | 加固后观察防护效果。 | 慢连接更快被关闭，超限连接被拒绝，正常请求可用性改善或受影响降低。 |
| V7 | 短报告记录对比。 | `03-delivery.md` 包含攻击现象、防御配置、验证步骤和结论。 |

### 7.2 选做接口预留

| 接口 | 预留方式 | 后续可扩展内容 |
| --- | --- | --- |
| 连接数采集 | `scripts/collect-metrics.ps1` | 使用 Windows 命令采集 `127.0.0.1:8080` 相关 TCP 连接数量。 |
| CSV 模板 | `observability/metrics-template.csv` | 字段可包括时间、连接数、成功请求数、失败请求数、备注。 |
| 指标说明 | `observability/notes.md` | 列出连接数、408/503 状态码、Nginx error log、正常请求延迟等指标。 |
| 资源曲线 | 暂不生成 | 必做完成后再决定是否用 CSV 数据绘图。 |

## 8. 报告结构

`03-delivery.md` 建议结构：

1. 标题和实验范围说明。
2. 实验安全边界：仅本地授权环境。
3. 我的选择理由/我的理解：为什么选择 Slowloris，以及它和网关入口层的关系。
4. 实验架构：攻击工具 -> Nginx 网关 -> Python 后端服务。
5. 环境与运行方式：Windows 本机、Python、Nginx 路径说明。
6. 默认基线配置与攻击现象。
7. Slowloris 攻击原理。
8. Nginx 防御原理与加固配置。
9. 防御前后对比。
10. 可观测性指标接口预留。
11. 不足与后续扩展：Slow POST、TLS 慢握手、资源曲线、指标采集。
12. 参考资料：课件脱敏引用和 Nginx 官方文档。

## 9. 人工检查点

在进入第四阶段并生成源码/报告后，需要人工或半自动检查：

| 检查点 | 检查内容 |
| --- | --- |
| C1 | 源码是否只允许本地目标。 |
| C2 | README 是否能让用户按 Windows 本机方式复现。 |
| C3 | Nginx 配置是否拆分为基线和加固两个文件。 |
| C4 | Nginx 配置是否只使用原生指令。 |
| C5 | 报告是否包含攻击现象和防御配置两个必做项。 |
| C6 | 报告是否有“我的选择理由/我的理解”段落。 |
| C7 | 选做项是否只做接口预留，未假装已经完成资源曲线。 |
| C8 | 阶段文件、源码注释和报告是否保持脱敏，不写真实公司名、人名、客户名、账号或本机绝对路径。 |
| C9 | 英文缩写和专业术语首次出现是否展开全称并给中文解释。 |
| C10 | 若本机无法运行 Nginx，报告必须明确说明验证受限，不能假装完成运行验证。 |

## 10. 风险控制

| 风险 | 控制措施 |
| --- | --- |
| Nginx 当前未安装或未加入 PATH。 | 第四阶段脚本支持 `-NginxHome` 参数，README 提示用户设置 Nginx 路径；不硬编码绝对路径。 |
| 攻击工具误用。 | 程序默认只允许本地回环地址，非本地地址直接拒绝。 |
| 本机负载过高。 | 默认连接数低，持续时间短，需显式参数才提高强度。 |
| 选做项范围膨胀。 | 第四阶段先完成必做；指标和资源曲线只预留接口，不阻塞主交付。 |
| 防御配置不适配攻击类型。 | 主线围绕 `client_header_timeout` 和 `limit_conn`，匹配 Slowloris 的请求头慢发送和连接占用特征。 |
| 引用资料不准确。 | 防御指令引用 Nginx 官方文档；课件引用只做脱敏改写，不复制敏感标识。 |
| 阶段越界。 | 本阶段只确认方案，不生成第四阶段正式源码和报告。 |

## 11. 第四阶段建议执行顺序

若用户确认本方案，第四阶段建议按以下顺序生成和验证：

1. 创建项目目录结构和占位目录。
2. 生成 Python 后端服务 `backend/app.py`。
3. 生成 Slowloris 工具 `attack/slowloris.py`，内置本地目标限制。
4. 生成 `nginx-baseline.conf` 和 `nginx-hardened.conf`。
5. 生成 Windows PowerShell 辅助脚本。
6. 生成 `README.md`。
7. 生成正式短报告 `03-delivery.md`。
8. 在不依赖 Nginx 已安装的前提下，先做静态检查：Python 语法检查、配置文件结构检查、脱敏检查、术语检查。
9. 如果本机可提供 Nginx 路径，再尝试实际启动和验证；如果不可用，在报告中明确标注运行验证限制。
10. 第四阶段完成后暂停，等待用户阅读产出内容。

## 12. 第三阶段结论

本次技术方案确定为：Windows 本机 Nginx 网关 + Python 后端服务 + Python Slowloris 攻击模拟工具 + Markdown 短报告。防御只使用 Nginx 原生配置，重点围绕请求头读取超时、连接限制和连接清理展开。选做项先不实现完整资源曲线，但在脚本和目录结构中预留观测接口。

当前阶段已完成。我先停在这里，等待你确认是否进入第四阶段。

D:\nginx-1.31.2\nginx-1.31.2下有nginx.exe，我只进行了下载，不会使用，请你帮我部署，然后生成我需要的内容。
