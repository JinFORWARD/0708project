# Slowloris Gateway Defense Lab

本项目用于完成“慢速攻击模拟与网关防御实践”培训作业。你可以把它理解成一个很小的本地实验室：用 Nginx（高性能 Web 服务器、反向代理和网关软件）放在入口，后面接一个 Python（解释型编程语言）写的后端服务，然后用 Slowloris（慢速 HTTP 请求头攻击）工具模拟“慢慢发请求头、拖住入口连接”的攻击。

本教程按 Windows（Microsoft Windows，微软桌面操作系统）新手步骤编写。你已经安装了 Nginx，路径是：

```text
C:\nginx-1.31.2
```

## 0. 先理解这个实验在做什么

### 0.1 什么是网关

Gateway（Gateway，网关）可以先简单理解为“入口”。客户端不直接访问后端服务，而是先访问网关，由网关决定怎么转发、怎么限制、怎么记录日志。

本实验里：

```text
浏览器/攻击工具 -> Nginx 网关 -> Python 后端服务
```

对应端口：

| 组件 | 地址 | 作用 |
| --- | --- | --- |
| Python 后端服务 | `http://127.0.0.1:18080` | 真正返回业务响应的服务。 |
| Nginx 网关 | `http://127.0.0.1:8080` | 对外入口，把请求转发给后端。 |
| Slowloris 工具 | 连接 `127.0.0.1:8080` | 模拟慢速请求头攻击。 |

### 0.2 什么是 Slowloris

HTTP（HyperText Transfer Protocol，超文本传输协议）请求头正常应该以一个空行结束。Slowloris 的做法是：先建立很多连接，发一点请求头，但迟迟不发结束空行，再隔一段时间补一点点头部内容，让网关一直等。

所以它的特点是：

1. 流量不一定很大。
2. 连接会被长期占住。
3. 后端服务可能还没收到请求，但网关入口已经被拖住。

### 0.3 本项目怎样防御

加固后的 Nginx 配置主要做两件事：

1. 缩短读取请求头的等待时间：`client_header_timeout`。
2. 限制单个 IP（Internet Protocol，互联网协议）能同时占用的连接数：`limit_conn`。

## 1. 安全边界

本项目只允许用于本地授权实验环境。攻击模拟工具默认只允许访问：

```text
127.0.0.1
localhost
::1
```

不得用于公网、第三方系统、生产系统或任何未授权目标。

## 2. 目录结构

你现在所在的 `0708project` 目录大致是这样：

```text
0708project
  README.md                         # 你正在读的教程
  03-delivery.md                    # 短报告
  backend
    app.py                          # Python 后端服务
  attack
    slowloris.py                    # Slowloris 本地模拟工具
  nginx
    conf
      nginx-baseline.conf           # 防御前：基线配置
      nginx-hardened.conf           # 防御后：加固配置
    logs                            # Nginx 日志目录
    temp                            # Nginx 临时目录
  scripts
    check-env.ps1                   # 检查环境
    start-backend.ps1               # 启动后端
    start-nginx.ps1                 # 启动 Nginx
    stop-nginx.ps1                  # 停止 Nginx
    run-baseline-test.ps1           # 运行基线攻击实验
    run-hardened-test.ps1           # 运行加固后攻击实验
    collect-metrics.ps1             # 预留的指标采集脚本
  observability
    metrics-template.csv            # 指标模板
    notes.md                        # 指标说明
```

## 3. 运行前准备

### 3.1 打开 PowerShell

推荐方式：

1. 在文件资源管理器中打开当前 `0708project` 文件夹。
2. 点击文件资源管理器顶部地址栏。
3. 输入 `powershell`。
4. 按回车。

这样打开的 PowerShell 会自动进入当前项目目录，不需要手动 `cd`。

如果你是从开始菜单打开 PowerShell，请先进入项目目录：

```powershell
cd "D:\Workspace\01-onboarding-training\2026-07-08-gateway-tech-intro\0708project"
```

这个路径已经全部使用英文目录名，避免 Nginx 在中文路径下启动失败。

### 3.2 如果 PowerShell 不允许运行脚本

如果运行 `.ps1` 脚本时出现执行策略错误，可以在当前 PowerShell 窗口临时执行：

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

这只影响当前 PowerShell 窗口，关闭窗口后会失效。

### 3.3 检查 Python 和 Nginx

在项目目录中运行：

```powershell
.\scripts\check-env.ps1 -NginxHome C:\nginx-1.31.2
```

你期望看到类似结果：

```text
Checking Python...
Python 3.x.x
Checking Nginx...
nginx version: nginx/1.31.2
Environment check finished.
```

如果提示找不到 Python，可以先试：

```powershell
py --version
```

如果 `py --version` 可以用，后续脚本都可以加上：

```powershell
-PythonExe py
```

例如：

```powershell
.\scripts\start-backend.ps1 -PythonExe py
```

如果 `python --version` 和 `py --version` 都提示找不到命令，先安装 Python 3，并在安装界面勾选 `Add python.exe to PATH`。安装完成后重新打开 PowerShell。

## 4. 第一次跑通：确认后端和网关能访问

建议开 2 个 PowerShell 窗口：

| 窗口 | 用途 |
| --- | --- |
| 窗口 A | 运行 Python 后端服务。 |
| 窗口 B | 启动 Nginx，并发请求测试。 |

### 4.1 窗口 A：启动 Python 后端

在窗口 A 运行：

```powershell
.\scripts\start-backend.ps1
```

如果你的 Python 命令是 `py`，运行：

```powershell
.\scripts\start-backend.ps1 -PythonExe py
```

看到类似输出即可：

```text
Local backend listening on http://127.0.0.1:18080
Press Ctrl+C to stop.
```

这个窗口不要关闭。后端服务需要一直开着。

### 4.2 窗口 B：直接测试后端

在窗口 B 运行：

```powershell
Invoke-WebRequest -UseBasicParsing http://127.0.0.1:18080/health
```

如果看到 `StatusCode : 200`，说明后端正常。

### 4.3 窗口 B：启动基线 Nginx

继续在窗口 B 运行：

```powershell
.\scripts\start-nginx.ps1 -Mode baseline -NginxHome C:\nginx-1.31.2
```

看到类似输出即可：

```text
Testing Nginx config: conf/nginx-baseline.conf
nginx: the configuration file ... syntax is ok
nginx: configuration file ... test is successful
Starting Nginx with conf/nginx-baseline.conf
Nginx should now listen on http://127.0.0.1:8080
```

### 4.4 窗口 B：通过 Nginx 测试后端

```powershell
Invoke-WebRequest -UseBasicParsing http://127.0.0.1:8080/health
```

如果看到 `StatusCode : 200`，说明：

```text
PowerShell -> Nginx 8080 -> Python 后端 18080
```

这条链路已经通了。

## 5. 做基线实验：未加固时模拟 Slowloris

现在建议开第 3 个 PowerShell 窗口：

| 窗口 | 用途 |
| --- | --- |
| 窗口 A | 后端服务，保持不动。 |
| 窗口 B | Nginx 网关，保持不动。 |
| 窗口 C | 运行攻击模拟工具。 |

### 5.1 窗口 C：运行基线攻击脚本

在窗口 C 进入项目目录后运行：

```powershell
.\scripts\run-baseline-test.ps1
```

如果你的 Python 命令是 `py`，运行：

```powershell
.\scripts\run-baseline-test.ps1 -PythonExe py
```

你也可以直接运行攻击工具：

```powershell
python .\attack\slowloris.py --host 127.0.0.1 --port 8080 --connections 30 --duration 60
```

预期输出类似：

```text
Local authorized lab only. Do not use this tool against external targets.
Target: 127.0.0.1:8080, connections=30, interval=10.0s, duration=60.0s
Opened 30 slow connections.
[round 1] alive=30 failed_since_last_round=0
```

这说明攻击工具正在维持一批“请求头还没发完”的连接。

### 5.2 观察基线现象

在窗口 B 或新窗口运行：

```powershell
Invoke-WebRequest -UseBasicParsing http://127.0.0.1:8080/health
```

也可以看本机连接：

```powershell
Get-NetTCPConnection -LocalPort 8080
```

可以把观察结果填到 [03-delivery.md](03-delivery.md) 的“攻击现象记录”表格里。

### 5.3 查看 Nginx 日志

访问日志：

```powershell
Get-Content .\nginx\logs\access.log -Tail 20
```

错误日志：

```powershell
Get-Content .\nginx\logs\error.log -Tail 40
```

注意：Slowloris 的未完成请求头不一定马上出现在访问日志里，因为请求还没完整进入 HTTP 处理流程。这个现象本身就可以写进报告。

## 6. 切换到加固配置

### 6.1 停止当前 Nginx

在窗口 B 运行：

```powershell
.\scripts\stop-nginx.ps1 -NginxHome C:\nginx-1.31.2
```

如果提示 Nginx 没有运行，可以忽略，然后继续下一步。

### 6.2 启动加固配置

```powershell
.\scripts\start-nginx.ps1 -Mode hardened -NginxHome C:\nginx-1.31.2
```

### 6.3 确认加固网关可访问

```powershell
Invoke-WebRequest -UseBasicParsing http://127.0.0.1:8080/health
```

看到 `StatusCode : 200` 后，再进入下一步。

## 7. 做加固后实验

在窗口 C 运行：

```powershell
.\scripts\run-hardened-test.ps1
```

如果你的 Python 命令是 `py`：

```powershell
.\scripts\run-hardened-test.ps1 -PythonExe py
```

预期变化：

1. 慢连接更容易被 Nginx 关闭。
2. 连接数超过限制时，部分连接会失败。
3. 正常 `/health` 请求更容易保持可用。
4. `nginx\logs\error.log` 里可能出现超时或连接限制相关记录。

把观察结果填到 [03-delivery.md](03-delivery.md) 的“加固配置下应观察的现象”表格里。

## 8. 可选：采集简单连接指标

选做项目前只是预留接口。如果必做内容已经完成，可以运行：

```powershell
.\scripts\collect-metrics.ps1
```

结果会写入：

```text
observability\metrics.csv
```

这个文件可以后续导入 Excel（Microsoft Excel，电子表格软件）画资源曲线。

## 9. 常见问题

### 9.1 提示端口被占用

如果 `8080` 或 `18080` 被占用，先查：

```powershell
Get-NetTCPConnection -LocalPort 8080
Get-NetTCPConnection -LocalPort 18080
```

如果是之前的 Nginx 没停掉，运行：

```powershell
.\scripts\stop-nginx.ps1 -NginxHome C:\nginx-1.31.2
```

后端服务窗口可以按 `Ctrl+C` 停止。

### 9.2 Nginx 提示配置测试失败

重点看报错里提到的文件和行号。常见原因：

1. 没在项目目录运行脚本。
2. `-NginxHome` 路径写错。
3. `nginx\logs` 或 `nginx\temp` 目录被占用或权限异常。

### 9.3 `python` 命令找不到

试试：

```powershell
py --version
```

如果可用，就把脚本命令改成带 `-PythonExe py`。

### 9.4 攻击工具拒绝运行

如果你把 `--host` 改成了外部地址，工具会拒绝运行。这是刻意设计的安全限制。本实验只允许本地授权目标。

## 10. 最后怎么交作业

本阶段已经生成短报告 [03-delivery.md](03-delivery.md)。你跑完实验后，主要补充这些位置：

1. “基线配置下应观察的现象”表格。
2. “加固配置下应观察的现象”表格。
3. 如果你做了指标采集，补充 `observability\metrics.csv` 或截图说明。

不需要改攻击工具去打外部地址，也不需要把资源曲线强行补齐。先把必做项跑通：环境、攻击现象、防御配置、短报告。

## 11. 参考资料

- Nginx 官方核心模块文档：<https://nginx.org/en/docs/http/ngx_http_core_module.html>
- Nginx 官方连接限制模块文档：<https://nginx.org/en/docs/http/ngx_http_limit_conn_module.html>
- Nginx 官方请求限速模块文档：<https://nginx.org/en/docs/http/ngx_http_limit_req_module.html>


