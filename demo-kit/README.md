# Demo Kit 使用说明

这个文件夹是明天展示的备用工具包，用来把今天手工跑过的流程自动化。脚本会打开多个前台 PowerShell（Windows 命令行工具）窗口，方便现场看到后端、Nginx（高性能 Web 服务器、反向代理和网关软件）、攻击工具、健康检查和指标采集的输出。

## 一键演示命令

先进入项目根目录：

```powershell
cd "D:\Workspace\01-onboarding-training\2026-07-08-gateway-tech-intro\0708project"
```

再运行：

```powershell
.\demo-kit\run-demo-tests.ps1 -NginxHome C:\nginx-1.31.2
```

如果你的 Python（解释型编程语言）命令是 `py`，运行：

```powershell
.\demo-kit\run-demo-tests.ps1 -NginxHome C:\nginx-1.31.2 -PythonExe py
```

## 脚本会做什么

1. 检查或启动本地后端服务 `127.0.0.1:18080`。
2. 停止可能残留的项目 Nginx 进程。
3. 启动基线配置 `nginx-baseline.conf`。
4. 同时打开三个前台窗口：连接指标采集、`/health` 健康检查、Slowloris（慢速 HTTP 请求头攻击）模拟。
5. 停止基线 Nginx。
6. 启动加固配置 `nginx-hardened.conf`。
7. 再次采集指标、健康检查和 Slowloris 输出。
8. 自动生成本轮 `demo-summary.md`。

## 输出位置

每次运行都会新建一个目录：

```text
observability\yyyyMMdd-HHmmss-demo\
```

里面包含：

| 文件 | 用途 |
| --- | --- |
| `baseline\baseline-attack.log` | 基线组攻击输出。 |
| `baseline\baseline-metrics.csv` | 基线组 TCP（Transmission Control Protocol，传输控制协议）连接数。 |
| `baseline\baseline-health.csv` | 基线组正常请求状态码和耗时。 |
| `hardened\hardened-attack.log` | 加固组攻击输出。 |
| `hardened\hardened-metrics.csv` | 加固组 TCP 连接数。 |
| `hardened\hardened-health.csv` | 加固组正常请求状态码和耗时。 |
| `demo-summary.md` | 自动汇总，现场讲解时可以直接打开。 |

## 展示时的建议说法

可以先说明：“这个脚本只是把我们今天的人工步骤自动串起来，目标不是攻击外部系统，只打 `127.0.0.1` 本机实验环境。”

如果现场时间紧，只展示三个窗口：

1. Slowloris 输出：看 `alive` 连接数变化。
2. Metrics 输出：看 8080 端口连接数变化。
3. Summary 输出：看基线和加固的对比结论。

## 常见问题

如果提示端口占用，先关掉旧的 Nginx 或后端窗口。项目 Nginx 可以运行：

```powershell
.\scripts\stop-nginx.ps1 -NginxHome C:\nginx-1.31.2
```

如果脚本执行策略报错，在当前 PowerShell 窗口临时运行：

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```
