---
title: Use select or omit to Prevent Over-Fetching and Data Leaks
impact: HIGH
impactDescription: Fetching all columns sends sensitive fields to clients and wastes bandwidth and memory
tags: prisma, security, performance, data-leaks
---

## Use select or omit to Prevent Over-Fetching and Data Leaks

**Impact: HIGH (sensitive fields exposed, excess bandwidth and memory used)**

Without explicit `select` or `omit`, Prisma fetches every column including sensitive ones like `password`, `refreshToken`, `twoFactorSecret`. These fields can accidentally leak into API responses if serialization is not locked down elsewhere.

**Incorrect (all columns fetched and potentially returned):**

```typescript
// BAD — fetches password, refreshToken, and all other columns
async findById(id: string) {
  return this.prisma.user.findUnique({ where: { id } });
}
```

**Correct (explicit select — only return what the caller needs):**

```typescript
// GOOD — explicit projection
async findById(id: string) {
  return this.prisma.user.findUnique({
    where: { id },
    select: {
      id: true,
      email: true,
      name: true,
      role: true,
      createdAt: true,
    },
  });
}
```

**Correct (omit sensitive fields — useful when the safe set is large):**

```typescript
// GOOD — omit sensitive columns
async findById(id: string) {
  return this.prisma.user.findUnique({
    where: { id },
    omit: {
      password: true,
      refreshToken: true,
      twoFactorSecret: true,
    },
  });
}
```

Reference: [Prisma — Select fields](https://www.prisma.io/docs/orm/prisma-client/queries/select-fields)
