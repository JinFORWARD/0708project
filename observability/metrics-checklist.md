# 可观测性指标清单

本文件补充“指标清单”选做项。这里的可观测性是指：当 Slowloris（慢速 HTTP 请求头攻击）发生时，我们用哪些指标判断“攻击是否正在发生、影响在哪里、防御是否生效”。

## 1. 本次已采集指标

| 指标 | 采集方式 | 基线组观察 | 加固组观察 | 展示时怎么讲 |
| --- | --- | --- | --- | --- |
| TCP（Transmission Control Protocol，传输控制协议）连接总数 | `scripts/collect-metrics.ps1` | 8080 端口总连接数稳定约 63。 | 很快下降到约 3。 | 基线会让慢连接持续占住入口；加固后连接被释放。 |
| TCP 已建立连接数 | `Get-NetTCPConnection -LocalPort 8080` | 已建立连接约 62。 | 从 62 快速降到 1-2。 | 这是 Slowloris 是否占住连接的直观证据。 |
| 正常请求状态码 | `demo-kit/health-check-loop.ps1` | `/health` 7 次均为 HTTP 200。 | `/health` 7 次均为 HTTP 200。 | 本机低强度实验下普通请求仍可用。 |
| 正常请求耗时 | `baseline-health.csv`、`hardened-health.csv` | 约 21-65 ms。 | 约 22-62 ms。 | 本轮压力不大，差异主要体现在慢连接生命周期。 |
| 攻击连接存活数 | `attack/slowloris.py` 输出 | 4 轮均 `alive=60`。 | 第 2 轮 `alive=0`。 | 加固配置能主动清理未完成请求头。 |
| Nginx access log（访问日志）状态码 | `nginx/logs/access.log` | 出现约 40 秒的 400。 | 出现约 5 秒的 408。 | 408 更直接说明请求头读取超时。 |
| Nginx error log（错误日志）关键词 | `nginx/logs/error.log` | `client prematurely closed connection`。 | `client timed out ... while reading client request headers`。 | 错误日志能帮助定位是入口读请求头阶段出问题。 |

## 2. 推荐补充指标

| 指标 | 说明 | Windows 采集方式 | 负责人建议 |
| --- | --- | --- | --- |
| CPU（Central Processing Unit，中央处理器）占用 | 判断攻击是否造成计算资源压力。 | `Get-Process nginx, python | Select-Object ProcessName, CPU` | 成员 B 主看，成员 A 补充 Nginx 进程。 |
| 内存占用 | 判断连接堆积是否导致内存增长。 | `Get-Process nginx, python | Select-Object ProcessName, WorkingSet64` | 成员 B。 |
| 进程句柄数 | Windows 下可近似观察资源占用；Linux 中类似 FD（File Descriptor，文件描述符）。 | `Get-Process nginx, python | Select-Object ProcessName, Handles` | 成员 B。 |
| HTTP（HyperText Transfer Protocol，超文本传输协议）4xx 状态码分布 | 观察 400、408、429、499 等异常状态是否集中出现。 | 统计 `nginx/logs/access.log`。 | 成员 B 主写，成员 A 解释 Nginx 配置含义。 |
| 408 请求超时数量 | 判断 `client_header_timeout` 是否生效。 | `Select-String nginx\logs\access.log -Pattern ' 408 '` | 成员 A/B 共同说明。 |
| 429 连接限制数量 | 判断 `limit_conn` 是否成为主导防护动作。 | `Select-String nginx\logs\access.log -Pattern ' 429 '` | 成员 A。 |
| 后端 QPS（Queries Per Second，每秒请求数） | 如果网关连接很多但后端请求不多，说明压力卡在入口层。 | 后端日志计数，或后续增加计数器。 | 成员 B。 |
| Nginx reading/writing/waiting | Nginx 连接状态细分，需要启用 `stub_status` 模块。 | 本次未启用，可作为改进项。 | 成员 A。 |

## 3. 展示用简表

| 阶段 | 连接数 | 正常访问 | Nginx 日志 | 结论 |
| --- | ---: | --- | --- | --- |
| 攻击前 | 低 | 正常 | 少量 200 | 环境可用。 |
| 基线攻击中 | 明显升高，已建立约 62 | 本轮仍正常 | 慢请求最后约 40 秒 400 | 慢连接可持续占用入口。 |
| 加固攻击中 | 快速下降到 1-2 | 本轮仍正常 | 约 5 秒 408 | 请求头超时配置生效。 |

## 4. 新人讲解重点

不要把指标讲成“越多越高级”。本次最关键的是三类证据：

1. 攻击工具输出：慢连接是否还活着。
2. TCP 连接数：入口资源是否被占住。
3. Nginx 日志：连接是被客户端关掉，还是被网关超时清理。

这三类证据连起来，就能说明“攻击现象”和“防御配置是否生效”。
