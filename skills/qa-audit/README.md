# qa-audit

**Version 1.0.0** — Local Workspace Skill — July 2026

> This skill is for AI agents performing structured backend code reviews and audits on NestJS + Prisma applications. It defines review dimensions, severity scales, and an audit deliverable format.

---

## What This Skill Does

When loaded, this skill turns the AI agent into a senior software engineer performing a structured review. It covers 12 dimensions:

1. **Correctness** — requirements, edge cases, logic errors, regressions
2. **Architecture** — module structure, thin controllers, separation of concerns
3. **Performance** — N+1 queries, unbounded lists, missing caching
4. **Database & Prisma** — transactions, select/omit, query efficiency
5. **Security** — input validation, error message safety, secrets
6. **Authorization & RBAC** — ownership checks, guard coverage, privilege escalation
7. **API Design** — HTTP semantics, status codes, pagination, Swagger
8. **Caching** — cache-aside patterns, invalidation, key scoping
9. **Scalability** — in-memory state, background jobs, horizontal scaling
10. **Maintainability** — readability, naming, test coverage
11. **Technical Debt** — workarounds, dead code, suppressed type errors
12. **Production Readiness** — health checks, structured logging, graceful shutdown

---

## Audit Deliverable

Every audit concludes with a structured summary:

- Overall Status (Pass / Pass with Notes / Fail)
- Severity (None / Low / Medium / High / Critical)
- Findings table
- Recommendations
- Risk Assessment
- Merge Readiness (Ready / Ready with Changes / Not Ready)

---

## Rule Files

| File | Topic |
|---|---|
| `performance-n1-queries.md` | Detecting and eliminating N+1 Prisma query patterns |
| `performance-unbounded-queries.md` | Enforcing pagination on all list endpoints |
| `database-select-omit.md` | Preventing over-fetching and sensitive field leaks |
| `database-transactions.md` | Wrapping multi-step writes in Prisma transactions |
| `authorization-ownership-checks.md` | Preventing IDOR / horizontal privilege escalation |
| `security-validation-pipe.md` | Global ValidationPipe with whitelist enforcement |
| `security-safe-error-messages.md` | Preventing stack trace and internals leakage |
| `architecture-thin-controllers.md` | Keeping controllers thin, logic in services |
| `caching-redis-cache-aside.md` | Cache-aside pattern with Redis |
| `production-structured-logging.md` | NestJS Logger vs console.log |
| `production-graceful-shutdown.md` | Prisma disconnect and queue drain on SIGTERM |

---

## Loading

This skill is auto-loaded by the steering configuration in `.kiro/steering/skill-autoload.md` whenever a QA, audit, review, or investigation task is detected.
