# PRD: Add Health Check Endpoint

**Author:** Platform Team
**Status:** In Progress
**Priority:** P1
**Target:** v2.4.0

## Overview

Production deployments currently lack a standardized health check endpoint, forcing
operations to rely on ad-hoc connectivity probes and manual verification. This PRD
defines a `/health` endpoint that reports the application's readiness by verifying
connectivity to critical backing services (database, Redis). The endpoint will be
consumed by Kubernetes liveness/readiness probes, the load balancer, and the ops
dashboard.

## Goals

- Provide a single HTTP endpoint that indicates whether the service is healthy.
- Surface granular status for each dependency so partial outages are identifiable.
- Keep response time under 500 ms even when a dependency is unreachable (use timeouts).
- Follow the RFC Health Check Response Format (draft-inadarei-api-health-check).

## Non-Goals

- Deep business-logic validation (e.g., verifying queue consumers are processing).
- Authentication on the health endpoint (it must be accessible without credentials).

## Acceptance Criteria

- `GET /health` returns `200 OK` with `{"status":"pass"}` when all checks pass.
- `GET /health` returns `503 Service Unavailable` with `{"status":"fail","checks":{...}}`
  when any dependency is unreachable, with per-check detail.
- Response Content-Type is `application/health+json`.
- Each dependency check times out after 2 seconds independently.
- The endpoint is excluded from request logging to avoid log noise from probes.

## Implementation Checklist

- [ ] Create GET /health endpoint returning JSON status
- [ ] Add database connectivity check
- [ ] Add Redis connectivity check
- [ ] Write unit tests for health check handler
- [ ] Add health check to API documentation

## Technical Notes

### Response Schema

```json
{
  "status": "pass",
  "version": "2.4.0",
  "checks": {
    "database": { "status": "pass", "latency_ms": 12 },
    "redis":    { "status": "pass", "latency_ms": 3 }
  }
}
```

### Failure Response

```json
{
  "status": "fail",
  "version": "2.4.0",
  "checks": {
    "database": { "status": "pass", "latency_ms": 14 },
    "redis":    { "status": "fail", "error": "connection refused", "latency_ms": 2000 }
  }
}
```

### Routing

Register the handler at `/health` on the existing HTTP router. The route should be
added before authentication middleware so it remains publicly accessible.

### Testing Strategy

- Unit tests: mock database and Redis clients, assert correct JSON for pass/fail/mixed.
- Integration tests (optional, not in this PRD scope): spin up containers and hit the
  real endpoint.
