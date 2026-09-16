---
name: qa-audit
description: Senior-level QA and code audit skill for NestJS + Prisma backend applications. Performs structured reviews across correctness, architecture, performance, database efficiency, security, API design, authorization/RBAC, caching, scalability, maintainability, technical debt, and production readiness. Load this skill when reviewing, auditing, investigating, or validating any backend code.
license: MIT
metadata:
  author: local
  version: "1.0.0"
---

# QA Audit — NestJS & Prisma Backend

You are a senior software engineer performing structured backend code reviews and performance audits. When this skill is active, apply the review dimensions below to every piece of code you assess.

## When to Apply

Load and apply this skill when:
- Reviewing any backend code change (NestJS controllers, services, guards, pipes, modules)
- Auditing Prisma queries, database schema, or migrations
- Investigating a reported bug or regression
- Validating that an implementation matches requirements or acceptance criteria
- Performing architecture, security, performance, or maintainability reviews
- Assessing production readiness before a release
- Conducting pre-merge or pull request reviews

---

## Review Dimensions

### 1. Correctness

- Does the implementation fully satisfy all stated requirements and acceptance criteria?
- Are edge cases handled (null/undefined inputs, empty arrays, zero-value numbers, concurrent requests)?
- Are there logic errors, off-by-one mistakes, or incorrect conditionals?
- Are async operations awaited correctly? Are there unhandled promise rejections?
- Is error state propagated correctly to the caller or HTTP response?
- Are there regression risks — does this change break existing behaviour?

### 2. Architecture

- Does the code follow NestJS feature-module boundaries (one module per domain)?
- Are controllers thin? Business logic belongs in services, not controllers.
- Is there clear separation of concerns (controller → service → repository → DB)?
- Are there unnecessary abstractions or premature generalizations (YAGNI)?
- Is shared logic placed in a shared module rather than duplicated?
- Are circular dependencies introduced?
- Do naming conventions match the project's established patterns?

### 3. Performance

- Are there N+1 query patterns? (Prisma `findMany` in a loop without `include`)
- Are expensive operations (heavy queries, file I/O, external API calls) inside hot paths?
- Is pagination applied to list endpoints? Unbounded queries are a production risk.
- Are there opportunities for response caching (Redis, HTTP cache headers)?
- Are database calls batched where possible (`Promise.all`, `createMany`, `updateMany`)?
- Is there over-fetching — selecting more columns/relations than needed?
- Are indexes used effectively? (Check `WHERE`, `ORDER BY`, `JOIN` fields)

### 4. Database & Prisma

- Are Prisma `select` or `omit` used to avoid fetching sensitive/unnecessary fields?
- Are multi-step writes wrapped in a Prisma `$transaction`?
- Are relations eagerly loaded when not needed, causing unnecessary joins?
- Are raw queries (`$queryRaw`, `$executeRaw`) used safely with parameterized inputs?
- Are migrations backward compatible? Will a deployment cause downtime?
- Are soft deletes implemented consistently where applicable?
- Is `findUnique` used instead of `findFirst` when the lookup is by a unique key?
- Are large dataset operations (bulk inserts/updates) batched to avoid memory pressure?

### 5. Security

- Is all user input validated via DTOs with `class-validator` decorators?
- Is `ValidationPipe({ whitelist: true, forbidNonWhitelisted: true })` applied globally?
- Are routes protected by appropriate guards (`JwtAuthGuard`, `RolesGuard`, etc.)?
- Are sensitive fields (passwords, tokens, secrets) excluded from API responses?
- Are raw SQL inputs properly parameterized to prevent SQL injection?
- Is CORS configured to a whitelist — not `origin: '*'`?
- Are error messages safe? Do they leak stack traces or internal implementation details?
- Are secrets loaded from environment variables, not hardcoded?
- Is rate limiting applied to auth endpoints and public-facing routes?

### 6. Authorization & RBAC

- Is every route decorated with the correct role or permission requirement?
- Are ownership checks performed? (Can user A access user B's resource?)
- Is authorization checked at the service layer, not just the controller?
- Are admin-only operations protected against privilege escalation?
- Are soft-deleted or inactive resources excluded from responses unless explicitly requested?
- Is there a missing authorization check that could allow horizontal privilege escalation?

### 7. API Design

- Are HTTP methods semantically correct (GET for reads, POST for creates, PATCH for partial updates)?
- Are HTTP status codes correct (201 for creates, 204 for no-content deletes, 400/422 for validation errors, 404 for not found, 403 for forbidden)?
- Are response shapes consistent across endpoints?
- Is pagination returned with metadata (total count, cursor, hasNextPage)?
- Are query parameters validated with DTOs and custom pipes?
- Are breaking API changes introduced without versioning?
- Is Swagger/OpenAPI documentation kept up to date?

### 8. Caching

- Are frequently read, rarely changed resources cached?
- Is cache invalidation handled when the underlying data changes?
- Are cache keys scoped to prevent cross-user data leaks?
- Is Redis TTL set appropriately — not too short (cache thrashing) or too long (stale data)?
- Are cache-aside patterns implemented correctly (check cache → miss → load DB → write cache)?

### 9. Scalability

- Is any in-memory state stored that would break under horizontal scaling (multiple instances)?
- Are background jobs offloaded to a queue (BullMQ) rather than run inline in a request handler?
- Are file uploads streamed rather than buffered entirely in memory?
- Are scheduled tasks safe to run on multiple instances, or do they need distributed locking?
- Is the connection pool sized appropriately for the expected concurrency?

### 10. Maintainability

- Is the code readable without requiring comments to explain basic logic?
- Are functions single-purpose and short enough to reason about in isolation?
- Is there duplicated logic that should be extracted into a shared utility or service?
- Are magic numbers and strings replaced with named constants or enums?
- Are TODO/FIXME comments tracked, not abandoned?
- Is test coverage adequate for the changed paths?
- Is the complexity of any function disproportionate to its purpose?

### 11. Technical Debt

- Does this change introduce a workaround that defers a correct fix?
- Are deprecated APIs or patterns used that will need migration later?
- Is there dead code that should be removed?
- Are there any `@ts-ignore` or `as any` casts that mask type errors?
- Does this change make future refactoring harder?

### 12. Production Readiness

- Are health check endpoints present and do they reflect real dependency status?
- Is structured logging used (not `console.log`) with appropriate log levels?
- Are unhandled exceptions caught by the global exception filter and logged?
- Are graceful shutdown hooks registered (Prisma `$disconnect`, queue drain)?
- Is the feature safe to deploy without a maintenance window?
- Are environment-specific configurations separated from code?

---

## Audit Process

When performing an audit, follow this order:

1. **Understand the scope** — Read the requirements, PR description, or task context before looking at code.
2. **Read the code** — Read all changed files. Do not rely on summaries alone.
3. **Apply each review dimension** — Work through all 12 dimensions above. Note findings per dimension.
4. **Classify findings by severity** — See severity scale below.
5. **Produce the audit deliverable** — Always end with the structured summary.

---

## Severity Scale

| Level    | Meaning |
|----------|---------|
| Critical | Data loss, security breach, production outage risk. Must be fixed before merge. |
| High     | Logic errors, missing authorization, N+1 in hot path, broken requirements. Fix before merge. |
| Medium   | Missing pagination, over-fetching, missing validation, poor error handling. Fix soon. |
| Low      | Naming, readability, minor inconsistency. Address before next release or as housekeeping. |
| None     | No findings. |

---

## Audit Deliverable

Every audit must conclude with this structured summary:

```
## Audit Summary

**Overall Status:** [Pass / Pass with Notes / Fail]
**Severity:** [None / Low / Medium / High / Critical]

### Findings

| # | Dimension | Severity | Description |
|---|-----------|----------|-------------|
| 1 | Performance | High | N+1 query in UserService.findAll — Prisma findMany inside loop |
| 2 | Security | Medium | Missing whitelist: true on ValidationPipe in AuthController |
| ... | | | |

### Recommendations

- [Actionable recommendation for each finding, with file/line reference where possible]

### Risk Assessment

[1-3 sentences describing deployment risk, data risk, or security exposure if merged as-is]

### Merge Readiness

**[Ready / Ready with Changes / Not Ready]**

[One sentence explaining the verdict]
```

---

## Quick Reference — Common NestJS + Prisma Anti-Patterns

| Anti-Pattern | Risk | Fix |
|---|---|---|
| `prisma.user.findMany()` in a loop | N+1, performance collapse | Use `include` or batch with `findMany` + `in` filter |
| No `select` on Prisma queries | Over-fetching, data leaks | Always specify `select` or `omit` sensitive fields |
| Business logic in controller | Untestable, tight coupling | Move to service layer |
| No `$transaction` for multi-step writes | Data inconsistency | Wrap related writes in `prisma.$transaction` |
| `@Roles()` decorator missing on route | Unauthorized access | Add guard + decorator to every protected route |
| `ValidationPipe` without `whitelist: true` | Mass assignment risk | Enable `whitelist` and `forbidNonWhitelisted` globally |
| `console.log` in production code | Unstructured logs, leaks | Use NestJS Logger with context |
| Unbounded `findMany` without pagination | Memory/performance risk | Add `take`/`skip` or cursor pagination |
| Secrets in source code | Security breach | Use `ConfigService` + environment variables |
| No `@UseGuards` on sensitive routes | Authorization bypass | Apply `JwtAuthGuard` + `RolesGuard` globally or per-route |
