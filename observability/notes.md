# Observability Notes

本文件是可观测性接口预留。Observability（Observability，可观测性）指通过日志、指标和链路信息理解系统状态。

## 建议指标

| 指标 | 含义 | 观察方式 |
| --- | --- | --- |
| TCP connection count | TCP（Transmission Control Protocol，传输控制协议）连接数量。 | `scripts/collect-metrics.ps1` 或 Windows `Get-NetTCPConnection`。 |
| Established connection count | 已建立连接数量。 | 观察慢连接是否长期保留。 |
| Nginx access log status | Nginx（Web 服务器、反向代理和网关软件）访问日志状态码。 | `nginx/logs/access.log`。 |
| Nginx error log timeout | Nginx 错误日志中的超时或连接限制信息。 | `nginx/logs/error.log`。 |
| Normal request result | 正常请求是否还能访问 `/health`。 | PowerShell `Invoke-WebRequest`。 |

## 后续扩展

必做完成后，可以把 `metrics.csv` 导入表格工具生成资源曲线。当前阶段不伪造资源曲线数据。
