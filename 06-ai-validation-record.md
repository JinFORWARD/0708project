# 第七阶段：AI 校验记录

## 1. 阶段状态

本文件为 SpecFlow-lite（培训作业轻量流程）第七阶段归档记录。

用户在 2026-07-08 明确要求：放弃现场自动测试脚本展示，以先前 agent 自动测试参数和日志为准；明天展示只展示源码、短报告、攻击现象、防御配置和指标清单；跳过第五阶段和第六阶段，直接进入第七阶段。因此本次未生成 `04-understanding-check-questions.md`，也未生成 `05-agent-*.md` 多 agent 问答文件。

## 2. 阶段产物清单

| 文件 | 状态 | 说明 |
| --- | --- | --- |
| `00-raw-materials-analysis.md` | 已完成 | 原始材料整理、核心要求、脱敏说明、术语表。 |
| `01-requirements-and-questions.md` | 已完成 | 要求澄清和问题确认。 |
| `02-approach-and-tech-selection.md` | 已完成 | 技术选型和产出方案。 |
| `03-delivery.md` | 已完成并更新 | 短报告，包含攻击现象、防御配置、防御前后对比、指标记录和展示口径。 |
| `04-understanding-check-questions.md` | 按用户要求跳过 | 用户明确要求跳过第五阶段。 |
| `05-agent-*.md` | 按用户要求跳过 | 用户明确要求跳过第六阶段。 |
| `06-ai-validation-record.md` | 已完成 | 本文件。 |
| `07-task-runtime-overrides-archive.md` | 已完成 | 本次临时覆盖规则归档。 |

## 3. 正式交付清单

| 类别 | 文件或目录 | 说明 |
| --- | --- | --- |
| 短报告 | `03-delivery.md` | 展示主文档，包含攻击现象和防御配置。 |
| 攻击源码 | `attack/slowloris.py` | Slowloris（慢速 HTTP 请求头攻击）本地模拟工具。 |
| 后端源码 | `backend/app.py` | Python（解释型编程语言）本地后端服务。 |
| Nginx 配置 | `nginx/conf/nginx-baseline.conf`、`nginx/conf/nginx-hardened.conf` | 防御前后配置对比。 |
| 指标清单 | `observability/metrics-checklist.md` | 选做项，说明发现和定位慢速攻击的核心指标。 |
| 实测日志 | `observability/20260708-174426-baseline/`、`observability/20260708-174607-hardened/` | agent 自动测试产生的有效日志和 CSV 数据。 |
| 展示讲稿 | `demo-kit/member-a-speaker-notes.md`、`demo-kit/member-b-speaker-notes.md`、`demo-kit/presentation-flow.md` | 双人讲解参考。 |

## 4. 交叉验证结论矩阵

| 检查点 | 结论 | 依据 |
| --- | --- | --- |
| 任务是否覆盖必做项 | 已覆盖 | 环境、攻击工具、攻击现象、防御配置、短报告均已形成。 |
| 攻击现象是否有实测依据 | 已覆盖 | 基线组日志显示 60 个慢连接持续存活；加固组日志显示第二轮慢连接归零。 |
| 防御配置是否可解释 | 已覆盖 | `client_header_timeout 5s`、`limit_conn`、`keepalive_timeout` 等在报告中解释。 |
| 指标清单是否补充 | 已覆盖 | `observability/metrics-checklist.md` 已新增。 |
| 现场展示策略是否一致 | 已调整 | README、讲解流程、成员 B 讲稿和报告均说明不现场运行自动脚本。 |
| 第五、第六阶段是否完成 | 未执行 | 用户明确要求跳过，风险在本文件中记录。 |

## 5. 用户确认和人工判断记录

1. 用户确认选择 Slowloris 作为攻击类型，使用 Python 和本地 Windows Nginx 环境。
2. 用户确认 Nginx 安装路径为 `C:\nginx-1.31.2`。
3. 用户因中文路径导致 Nginx 启动失败，将项目迁移到 `D:\Workspace\01-onboarding-training\2026-07-08-gateway-tech-intro\0708project`。
4. 用户要求增加新人教程、自动测试结果填入报告、指标清单、双人展示稿和流程。
5. 用户最终判断：放弃现场脚本复现，以先前 agent 自动测试参数和日志为准；跳过第五、第六阶段，直接进入第七阶段。

## 6. 未解决问题和限制

1. 第五阶段理解检测题和第六阶段多 agent 问答未执行，原因是用户明确要求跳过；这会减少对展示问答盲区的预先发现。
2. 自动测试脚本保留为历史存档，但当前不作为现场展示内容。
3. 资源曲线未绘制成图片，只保留 CSV 数据和指标清单。
4. 本次为本地低强度实验，不能直接代表生产环境参数选择。

## 7. 脱敏处理执行记录

本次交付文件未写入真实公司名、客户名、账号、密钥或未公开系统细节。作业中的路径为本机实验路径，展示材料中只保留完成复现实验所需的本地路径和本地回环地址 `127.0.0.1`。

## 8. 术语和英文缩写检查记录

已在主要产出中对 Nginx、HTTP（HyperText Transfer Protocol，超文本传输协议）、TCP（Transmission Control Protocol，传输控制协议）、TLS（Transport Layer Security，传输层安全协议）、CSV（Comma-Separated Values，逗号分隔值）、WAF（Web Application Firewall，Web 应用防火墙）等术语进行首次解释。新增的指标清单和展示说明也补充了关键缩写解释。

## 9. 最终展示建议

明天展示时按以下顺序：

1. 先用 `03-delivery.md` 讲目标、架构和结论。
2. 再用 `attack/slowloris.py` 和 `nginx/conf/*.conf` 说明源码与配置。
3. 用 `03-delivery.md` 第 5、8、9 节讲攻击现象、防御对比和指标。
4. 用 `observability/metrics-checklist.md` 回答“如何发现和定位这类攻击”。
5. 如果被问为什么不现场跑，说明：这轮实验结果已经由 agent 在本机自动跑过，并写入日志和短报告；现场脚本复现暂时不够稳定，为避免展示时间被环境问题打断，本次以固定实验参数、已有日志和报告结论为准。
