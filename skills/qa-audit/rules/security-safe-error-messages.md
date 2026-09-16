---
title: Never Leak Stack Traces or Internal Error Details to API Consumers
impact: HIGH
impactDescription: Stack traces expose internal file paths, library versions, and logic that attackers use for reconnaissance
tags: security, error-handling, production, nestjs
---

## Never Leak Stack Traces or Internal Error Details to API Consumers

**Impact: HIGH (stack traces are a security and information-disclosure risk)**

Unhandled exceptions in NestJS default to returning a 500 with a generic message. However, if a global exception filter is not configured or is misconfigured, raw errors — including stack traces, Prisma error codes, SQL fragments, and internal file paths — can reach the client response body.

**Incorrect (no global exception filter — raw Prisma/JS errors escape):**

```typescript
// BAD — no global filter; a Prisma unique constraint error returns raw DB internals
// Response body: { "message": "Unique constraint failed on the fields: (`email`)", "code": "P2002", ... }
```

**Incorrect (exception filter that forwards the raw error):**

```typescript
// BAD
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const response = host.switchToHttp().getResponse();
    response.status(500).json({ error: exception }); // leaks everything
  }
}
```

**Correct (safe global exception filter):**

```typescript
// GOOD — logs internally, returns only safe messages externally
import { ExceptionFilter, Catch, ArgumentsHost, HttpException, HttpStatus, Logger } from '@nestjs/common';

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse();
    const request = ctx.getRequest();

    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    const message =
      exception instanceof HttpException
        ? exception.getResponse()
        : 'Internal server error';

    // Log the full error internally
    this.logger.error(
      `${request.method} ${request.url} → ${status}`,
      exception instanceof Error ? exception.stack : String(exception),
    );

    // Return only safe information to the client
    response.status(status).json({
      statusCode: status,
      message: typeof message === 'string' ? message : (message as any).message,
      timestamp: new Date().toISOString(),
      path: request.url,
    });
  }
}
```

**Register globally in main.ts:**

```typescript
app.useGlobalFilters(new AllExceptionsFilter());
```

Reference: [NestJS — Exception filters](https://docs.nestjs.com/exception-filters)
