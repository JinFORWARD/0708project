# Slowloris Gateway Defense Lab

本项目用于完成“慢速攻击模拟与网关防御实践”培训作业。实验对象是本地 Nginx（高性能 Web 服务器、反向代理和网关软件）网关与 Python（解释型编程语言）后端服务，攻击类型选择 Slowloris（慢速 HTTP 请求头攻击，HTTP 是 HyperText Transfer Protocol，超文本传输协议）。

## 安全边界

本项目只允许用于本地授权实验环境。攻击模拟工具默认只允许访问 `127.0.0.1`、`localhost` 或 `::1`，不得用于公网、第三方系统、生产系统或任何未授权目标。

## 目录结构

```text
backend/app.py                     # 本地后端服务
attack/slowloris.py                # 本地 Slowloris 模拟工具
nginx/conf/nginx-baseline.conf     # 未加固基线配置
nginx/conf/nginx-hardened.conf     # Nginx 原生加固配置
scripts/*.ps1                      # Windows PowerShell 辅助脚本
observability/                     # 可观测性指标接口预留
03-delivery.md                     # 短报告
```

## 前置条件

1. Windows（Microsoft Windows，微软桌面操作系统）。
2. Python 3（建议 3.10 或更新版本）。
3. Nginx Windows 版。若 `nginx.exe` 不在 `PATH` 中，请在脚本里传入 `-NginxHome <NGINX_HOME>`。

当前自动检查环境中可用 Python 3.12.13，但未检测到 `nginx` 命令。因此，实际启动 Nginx 需要你在本机安装 Nginx Windows 版或提供 `nginx.exe` 所在目录。

## 运行步骤

### 1. 检查环境

```powershell
.\scripts\check-env.ps1
.\scripts\check-env.ps1 -NginxHome C:\nginx
```

### 2. 启动后端服务

新开一个 PowerShell 窗口：

```powershell
.\scripts\start-backend.ps1
```

后端默认监听：

```text
http://127.0.0.1:18080
```

### 3. 启动基线 Nginx 配置

新开一个 PowerShell 窗口：

```powershell
.\scripts\start-nginx.ps1 -Mode baseline -NginxHome C:\nginx
```

基线网关默认监听：

```text
http://127.0.0.1:8080
```

健康检查：

```powershell
Invoke-WebRequest -UseBasicParsing http://127.0.0.1:8080/health
```

### 4. 运行基线 Slowloris 实验

新开一个 PowerShell 窗口：

```powershell
.\scripts\run-baseline-test.ps1
```

也可以直接运行攻击工具：

```powershell
python .\attack\slowloris.py --host 127.0.0.1 --port 8080 --connections 30 --duration 60
```

### 5. 切换到加固配置

停止 Nginx：

```powershell
.\scripts\stop-nginx.ps1 -NginxHome C:\nginx
```

启动加固配置：

```powershell
.\scripts\start-nginx.ps1 -Mode hardened -NginxHome C:\nginx
```

运行加固后实验：

```powershell
.\scripts\run-hardened-test.ps1
```

## 可观测性接口预留

Observability（Observability，可观测性）接口目前只做预留。必做内容完成后，可以运行：

```powershell
.\scripts\collect-metrics.ps1
```

结果会写入：

```text
observability/metrics.csv
```

## 预期观察点

基线配置下，Slowloris 会保持多个未完成请求头连接，Nginx 需要等待请求头结束或超时。加固配置下，`client_header_timeout` 会缩短等待请求头的时间，`limit_conn` 会限制单个 IP（Internet Protocol，互联网协议）可占用的并发连接数。

## 参考资料

- Nginx 官方核心模块文档：<https://nginx.org/en/docs/http/ngx_http_core_module.html>
- Nginx 官方连接限制模块文档：<https://nginx.org/en/docs/http/ngx_http_limit_conn_module.html>
- Nginx 官方请求限速模块文档：<https://nginx.org/en/docs/http/ngx_http_limit_req_module.html>
