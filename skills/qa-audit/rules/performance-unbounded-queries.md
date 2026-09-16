---
title: Enforce Pagination on All List Endpoints
impact: CRITICAL
impactDescription: Unbounded queries load entire tables into memory and can exhaust both database and application memory
tags: prisma, performance, pagination, api
---

## Enforce Pagination on All List Endpoints

**Impact: CRITICAL (unbounded queries are a production memory and latency risk)**

Any `findMany` call without a `take` limit will return every matching row. As data grows this causes response latency spikes, memory pressure, and potential OOM crashes. All list endpoints must enforce a maximum page size.

**Incorrect (no limit applied):**

```typescript
// BAD — returns all records, unbounded
async findAll() {
  return this.prisma.order.findMany({
    where: { status: 'PENDING' },
  });
}
```

**Correct (cursor-based pagination, preferred for large datasets):**

```typescript
// GOOD — cursor pagination with a hard cap
async findAll(cursor?: string, take = 20) {
  const limit = Math.min(take, 100); // hard cap
  return this.prisma.order.findMany({
    where: { status: 'PENDING' },
    take: limit,
    skip: cursor ? 1 : 0,
    cursor: cursor ? { id: cursor } : undefined,
    orderBy: { createdAt: 'desc' },
  });
}
```

**Correct (offset pagination, acceptable for smaller datasets):**

```typescript
// GOOD — offset pagination
async findAll(page = 1, pageSize = 20) {
  const limit = Math.min(pageSize, 100);
  const [items, total] = await this.prisma.$transaction([
    this.prisma.order.findMany({
      where: { status: 'PENDING' },
      skip: (page - 1) * limit,
      take: limit,
    }),
    this.prisma.order.count({ where: { status: 'PENDING' } }),
  ]);
  return { items, total, page, pageSize: limit };
}
```

Reference: [Prisma — Pagination](https://www.prisma.io/docs/orm/prisma-client/queries/pagination)
