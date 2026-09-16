# Sections

This file defines all sections, their ordering, impact levels, and descriptions.
The section ID (in parentheses) is the filename prefix used to group rules.

---

## 1. Correctness (correctness)

**Impact:** CRITICAL
**Description:** Code must fully satisfy requirements, handle edge cases, and not introduce regressions. Logic errors and unhandled async failures cause production incidents.

## 2. Architecture (architecture)

**Impact:** HIGH
**Description:** NestJS feature-module structure, thin controllers, separation of concerns, and YAGNI discipline keep the codebase maintainable as it scales.

## 3. Performance (performance)

**Impact:** HIGH
**Description:** N+1 queries, unbounded list endpoints, and missing caching are the most common production performance killers in NestJS/Prisma applications.

## 4. Database (database)

**Impact:** CRITICAL
**Description:** Prisma query correctness, transaction safety, over-fetching, and missing indexes directly impact data integrity and application throughput.

## 5. Security (security)

**Impact:** CRITICAL
**Description:** Input validation, authorization guards, safe error messages, and secrets management prevent unauthorized access and data breaches.

## 6. Authorization (authorization)

**Impact:** CRITICAL
**Description:** Every route must be protected with the correct guard and role. Missing ownership checks enable horizontal privilege escalation.

## 7. API Design (api)

**Impact:** MEDIUM
**Description:** Correct HTTP semantics, consistent response shapes, proper status codes, and up-to-date Swagger docs improve API consumer experience and debuggability.

## 8. Caching (caching)

**Impact:** HIGH
**Description:** Cache frequently read data to reduce database load. Invalidate correctly to avoid serving stale responses. Scope cache keys to prevent data leaks.

## 9. Scalability (scalability)

**Impact:** HIGH
**Description:** In-memory state, inline background work, and unbuffered file handling break under horizontal scaling. Design for multiple instances from the start.

## 10. Maintainability (maintainability)

**Impact:** MEDIUM
**Description:** Readable, single-purpose functions, no magic values, and adequate test coverage keep the codebase approachable and reduce future defect rates.

## 11. Technical Debt (debt)

**Impact:** MEDIUM
**Description:** Workarounds, deprecated APIs, dead code, and suppressed type errors accumulate and compound over time. Track and address them explicitly.

## 12. Production Readiness (production)

**Impact:** HIGH
**Description:** Health checks, structured logging, global exception handling, and graceful shutdown are baseline requirements for safely operating a service in production.
