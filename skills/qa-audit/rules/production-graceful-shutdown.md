---
title: Register Graceful Shutdown Hooks for Prisma and Queues
impact: HIGH
impactDescription: Missing shutdown hooks cause in-flight requests and queued jobs to be abandoned when the process is killed
tags: production, nestjs, prisma, deployment
---

## Register Graceful Shutdown Hooks for Prisma and Queues

**Impact: HIGH (abrupt process termination leaves open DB connections and drops in-flight work)**

When a container or process receives `SIGTERM` (from Kubernetes, systemd, or `Ctrl+C`), NestJS needs to cleanly finish in-flight requests, drain queue processors, and disconnect from the database before the process exits. Without `enableShutdownHooks()` and proper `onModuleDestroy` implementations, the process exits immediately, dropping active work and leaking database connections.

**Incorrect (no shutdown hooks):**

```typescript
// BAD — Prisma connection is not closed, in-flight requests are dropped
async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  await app.listen(3000);
}
```

**Correct (shutdown hooks enabled in main.ts):**

```typescript
// GOOD
async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableShutdownHooks(); // listens for SIGTERM/SIGINT
  await app.listen(3000);
}
```

**Correct (Prisma disconnects on module destroy):**

```typescript
// GOOD — ensures clean Prisma disconnect on shutdown
import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  async onModuleInit() {
    await this.$connect();
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
```

**Correct (BullMQ queue closes gracefully):**

```typescript
// GOOD — worker finishes the current job before shutting down
@Injectable()
export class OrderWorker implements OnModuleDestroy {
  constructor(private readonly worker: Worker) {}

  async onModuleDestroy() {
    await this.worker.close();
  }
}
```

Reference: [NestJS — Lifecycle events](https://docs.nestjs.com/fundamentals/lifecycle-events)
