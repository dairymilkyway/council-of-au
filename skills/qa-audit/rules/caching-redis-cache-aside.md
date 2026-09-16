---
title: Cache Frequently Read, Rarely Changed Data with Redis
impact: HIGH
impactDescription: Caching reduces database load and response latency for hot read paths by orders of magnitude
tags: caching, redis, performance, nestjs
---

## Cache Frequently Read, Rarely Changed Data with Redis

**Impact: HIGH (caching can reduce DB load by 90%+ on read-heavy endpoints)**

Configuration data, reference lists, user profiles, and aggregate counts change infrequently but are read on every request. Without caching, every request hits the database unnecessarily. Apply cache-aside: check cache first, load from DB on miss, write to cache, invalidate on mutation.

**Incorrect (no caching — every request hits the database):**

```typescript
// BAD — fetches all categories from DB on every request
async getCategories() {
  return this.prisma.category.findMany({ orderBy: { name: 'asc' } });
}
```

**Correct (cache-aside pattern):**

```typescript
// GOOD — cache hit avoids DB entirely
import { Injectable } from '@nestjs/common';
import { InjectRedis } from '@nestjs-modules/ioredis';
import Redis from 'ioredis';

@Injectable()
export class CategoryService {
  private readonly CACHE_KEY = 'categories:all';
  private readonly TTL = 300; // 5 minutes

  constructor(
    private readonly prisma: PrismaService,
    @InjectRedis() private readonly redis: Redis,
  ) {}

  async getCategories() {
    const cached = await this.redis.get(this.CACHE_KEY);
    if (cached) return JSON.parse(cached);

    const categories = await this.prisma.category.findMany({ orderBy: { name: 'asc' } });
    await this.redis.setex(this.CACHE_KEY, this.TTL, JSON.stringify(categories));
    return categories;
  }

  async createCategory(dto: CreateCategoryDto) {
    const category = await this.prisma.category.create({ data: dto });
    await this.redis.del(this.CACHE_KEY); // invalidate on mutation
    return category;
  }
}
```

**Cache key scoping (prevent cross-user leaks):**

```typescript
// GOOD — user-scoped cache key prevents data from leaking between users
private getCacheKey(userId: string) {
  return `user:${userId}:profile`;
}
```

**What to cache vs. what not to cache:**

| Cache ✅ | Do not cache ❌ |
|---|---|
| Category/tag lists | User financial data |
| Configuration values | Auth tokens (use dedicated store) |
| Aggregate counts (approximate) | Real-time inventory |
| Slow aggregate queries | Data that changes on every write |

Reference: [NestJS — Caching](https://docs.nestjs.com/techniques/caching)
