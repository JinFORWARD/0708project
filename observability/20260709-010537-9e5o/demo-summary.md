# Demo Test Summary

Run directory: 20260709-010537-9e5o

## Baseline

- Attack: Target: 127.0.0.1:8080, connections=60, interval=10.0s, duration=35.0s; last round: [round 4] alive=60 failed_since_last_round=0.
- TCP metrics: first total/established=8/2; last total/established=69/63.
- Health checks: 7/7 health checks returned 200; elapsed 13-46 ms.

## Hardened

- Attack: Target: 127.0.0.1:8080, connections=60, interval=10.0s, duration=35.0s; last round: [round 2] alive=0 failed_since_last_round=60; server closed the slow connections.
- TCP metrics: first total/established=10/2; last total/established=11/1.
- Health checks: 7/7 health checks returned 200; elapsed 16-42 ms.

## How to explain this result

- Baseline keeps unfinished HTTP request headers alive for longer, so slow connections can occupy the gateway.
- Hardened config uses client_header_timeout 5s, so incomplete headers are closed quickly and Nginx returns 408-like timeout records.
- Normal /health checks are included to show whether ordinary users are still served during the experiment.
