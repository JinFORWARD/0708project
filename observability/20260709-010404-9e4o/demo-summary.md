# Demo Test Summary

Run directory: $runName

## Baseline

- Attack: Target: 127.0.0.1:8080, connections=5, interval=10.0s, duration=8.0s; last round: [round 1] alive=5 failed_since_last_round=0.
- TCP metrics: first total/established=3/2; last total/established=9/8.
- Health checks: 3/3 health checks returned 200; elapsed 23-43 ms.

## Hardened

- Attack: Target: 127.0.0.1:8080, connections=5, interval=10.0s, duration=8.0s; last round: [round 1] alive=5 failed_since_last_round=0.
- TCP metrics: first total/established=6/2; last total/established=7/3.
- Health checks: 3/3 health checks returned 200; elapsed 26-44 ms.

## How to explain this result

- Baseline keeps unfinished HTTP request headers alive for longer, so slow connections can occupy the gateway.
- Hardened config uses client_header_timeout 5s, so incomplete headers are closed quickly and Nginx returns 408-like timeout records.
- Normal /health checks are included to show whether ordinary users are still served during the experiment.
