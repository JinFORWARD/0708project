# Demo Kit 存档说明

这个文件夹原本用于把测试流程自动化，并尝试在展示时打开多个前台 PowerShell（Windows 命令行工具）窗口。但当前展示策略已经调整：明天不现场运行自动测试脚本，只展示源码、Nginx（高性能 Web 服务器、反向代理和网关软件）配置、短报告和指标清单。

## 当前展示策略

展示材料以这些文件为准：

| 文件或目录 | 展示用途 |
| --- | --- |
| `03-delivery.md` | 短报告，包含攻击现象、防御配置、防御前后对比和指标记录。 |
| `attack/slowloris.py` | Slowloris（慢速 HTTP 请求头攻击）模拟源码。 |
| `backend/app.py` | Python（解释型编程语言）后端服务源码。 |
| `nginx/conf/nginx-baseline.conf` | 基线 Nginx 配置。 |
| `nginx/conf/nginx-hardened.conf` | 加固 Nginx 配置。 |
| `observability/metrics-checklist.md` | 指标清单选做项。 |
| `observability/20260708-174426-baseline/` | 已采集的基线组日志和 CSV（Comma-Separated Values，逗号分隔值）数据。 |
| `observability/20260708-174607-hardened/` | 已采集的加固组日志和 CSV 数据。 |

## 如果被问为什么不现场跑

建议统一回答：

> 这轮实验结果已经由 agent 在本机自动跑过，并写入日志和短报告。现场脚本复现暂时不够稳定，为了避免展示时间被环境问题打断，本次以固定实验参数、已有日志和报告结论为准。

## 本文件夹保留什么

| 文件 | 当前用途 |
| --- | --- |
| `member-a-speaker-notes.md` | 成员 A 讲解稿。 |
| `member-b-speaker-notes.md` | 成员 B 讲解稿。 |
| `presentation-flow.md` | 双人展示流程。 |
| `run-demo-tests.ps1` | 历史自动测试脚本，当前不建议现场运行。 |
| `health-check-loop.ps1` | 历史辅助脚本，当前不建议现场运行。 |
| `summarize-demo-results.ps1` | 历史辅助脚本，当前不建议现场运行。 |

## 新人展示提醒

不要把重点放在“现场能不能跑起来”。本次作业的核心交付是：源码结构清楚、攻击现象有记录、防御配置能解释、指标清单能说明如何发现和定位问题。
