---
title: Use NestJS Logger Instead of console.log
impact: MEDIUM
impactDescription: console.log is unstructured and unscoped; NestJS Logger provides log levels, context, and integrates with monitoring tools
tags: logging, production, maintainability, nestjs
---

## Use NestJS Logger Instead of console.log

**Impact: MEDIUM (unstructured logs are hard to filter, query, and monitor in production)**

`console.log` outputs plain strings with no level, no timestamp, and no context. In production, log aggregation tools (Datadog, Loki, CloudWatch) rely on structured output and severity levels for alerting and filtering. The NestJS `Logger` class provides this out of the box and is replaceable with a custom logger (Winston, Pino) without changing call sites.

**Incorrect (console.log in service):**

```typescript
// BAD — no log level, no context, not filterable
@Injectable()
export class OrderService {
  async create(dto: CreateOrderDto) {
    console.log('Creating order for user:', dto.userId);
    try {
      const order = await this.prisma.order.create({ data: dto });
      console.log('Order created:', order.id);
      return order;
    } catch (err) {
      console.error('Failed to create order:', err);
      throw err;
    }
  }
}
```

**Correct (NestJS Logger with module context):**

```typescript
// GOOD — structured, leveled, scoped logs
import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class OrderService {
  private readonly logger = new Logger(OrderService.name);

  async create(dto: CreateOrderDto) {
    this.logger.log(`Creating order for userId=${dto.userId}`);
    try {
      const order = await this.prisma.order.create({ data: dto });
      this.logger.log(`Order created orderId=${order.id}`);
      return order;
    } catch (err) {
      this.logger.error(`Failed to create order for userId=${dto.userId}`, err.stack);
      throw err;
    }
  }
}
```

**Log level guidelines:**

| Level   | When to use |
|---------|-------------|
| `verbose` | Very detailed tracing, disabled in production |
| `debug`   | Debugging information, disabled in production |
| `log`     | Normal operational events |
| `warn`    | Recoverable issues that should be investigated |
| `error`   | Failures that require attention; always include `err.stack` |

Reference: [NestJS — Logger](https://docs.nestjs.com/techniques/logger)
