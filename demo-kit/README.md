# Demo Kit 使用说明

这个文件夹提供备用的一键自动测试脚本。主展示仍建议以 `03-delivery.md`、源码、Nginx（高性能 Web 服务器、反向代理和网关软件）配置和指标清单为主；如果现场需要补充演示，可以运行这里的一键脚本。

当前脚本已修复并完成过一轮默认参数完整验证。最新成功数据目录：

```text
observability\20260709-010940-9e9o\
```

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
2. 停止可能残留的项目 Nginx；没有旧 pid 文件时会正常跳过。
3. 启动基线配置 `nginx-baseline.conf`。
4. 打开前台 PowerShell（Windows 命令行工具）窗口展示指标采集、`/health` 健康检查和 Slowloris（慢速 HTTP 请求头攻击）模拟。
5. 停止基线 Nginx。
6. 启动加固配置 `nginx-hardened.conf`。
7. 再次采集指标、健康检查和 Slowloris 输出。
8. 自动生成本轮 `demo-summary.md`。

## 输出位置

每次运行都会新建一个目录：

```text
observability\yyyyMMdd-HHmmss-xxxxo\
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

## 最新成功结果

`observability\20260709-010940-9e9o\demo-summary.md` 显示：

- 基线组：60 个慢连接，最后一轮仍 `alive=60`。
- 加固组：第二轮 `alive=0`，服务端关闭慢连接。
- 两组 `/health` 均为 7/7 次 HTTP 200。

## 展示建议

主展示可以不运行脚本，直接讲 `03-delivery.md`。如果时间允许或被要求现场复现，再运行一键脚本。运行后重点展示三个窗口或结果：

1. Slowloris 输出：看基线 `alive=60`、加固 `alive=0`。
2. Metrics 输出：看 8080 端口 TCP 连接数变化。
3. `demo-summary.md`：看自动汇总结论。

## 常见问题

如果提示端口占用，先运行：

```powershell
.\scripts\stop-nginx.ps1 -NginxHome C:\nginx-1.31.2
```

如果脚本执行策略报错，在当前 PowerShell 窗口临时运行：

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```
