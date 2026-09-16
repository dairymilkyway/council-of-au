---
title: Detect and Eliminate N+1 Query Patterns
impact: CRITICAL
impactDescription: N+1 queries cause exponential database load — 100 users = 101 queries instead of 1"
tags: prisma, performance, database, n+1
---

## Detect and Eliminate N+1 Query Patterns

**Impact: CRITICAL (N+1 queries cause exponential database load)**

An N+1 pattern occurs when code issues one query to fetch a list, then issues one additional query per item to fetch related data. In Prisma this most often appears as a `findMany` call followed by per-record lookups inside a loop or `.map()`. At scale (hundreds of records) this collapses performance.

**Incorrect (separate query per item inside a loop):**

```typescript
// BAD — 1 query for users + 1 query per user for their profile = N+1
async findAllWithProfiles() {
  const users = await this.prisma.user.findMany();
  return Promise.all(
    users.map(user => this.prisma.profile.findUnique({ where: { userId: user.id } }))
  );
}
```

**Correct (single query with `include`):**

```typescript
// GOOD — 1 query with a JOIN
async findAllWithProfiles() {
  return this.prisma.user.findMany({
    include: { profile: true },
  });
}
```

**Correct (batch lookup with `in` filter when `include` is not appropriate):**

```typescript
// GOOD — 2 queries total regardless of list size
async findAllWithProfiles() {
  const users = await this.prisma.user.findMany();
  const userIds = users.map(u => u.id);
  const profiles = await this.prisma.profile.findMany({
    where: { userId: { in: userIds } },
  });
  const profileMap = new Map(profiles.map(p => [p.userId, p]));
  return users.map(u => ({ ...u, profile: profileMap.get(u.id) }));
}
```

Reference: [Prisma — Relation queries](https://www.prisma.io/docs/orm/prisma-client/queries/relation-queries)
