---
title: Enable Global ValidationPipe with Whitelist and ForbidNonWhitelisted
impact: CRITICAL
impactDescription: Without whitelist, extra properties pass through and can be used for mass assignment attacks
tags: validation, security, nestjs, dto
---

## Enable Global ValidationPipe with Whitelist and ForbidNonWhitelisted

**Impact: CRITICAL (mass assignment and injection risk without whitelist)**

NestJS's `ValidationPipe` must be configured globally with `whitelist: true` and `forbidNonWhitelisted: true`. Without `whitelist`, extra properties sent by a client silently pass through to the service layer even if they are not defined in the DTO. This enables mass assignment attacks — for example, a client could send `{ "role": "admin" }` alongside a registration payload.

**Incorrect (ValidationPipe not applied globally, or applied without whitelist):**

```typescript
// BAD — no global validation, or weak configuration
async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.useGlobalPipes(new ValidationPipe()); // whitelist defaults to false
  await app.listen(3000);
}
```

**Incorrect (DTO defined but extra fields still pass through):**

```typescript
// BAD — role is not in the DTO, but without whitelist it could be injected
class CreateUserDto {
  @IsEmail() email: string;
  @IsString() password: string;
  // 'role' is not here, but without whitelist it still reaches the service
}
```

**Correct (strict global configuration):**

```typescript
// GOOD — whitelist strips undeclared props; forbidNonWhitelisted rejects the request outright
async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,             // strip properties not in the DTO
      forbidNonWhitelisted: true,  // reject requests that contain undeclared properties
      transform: true,             // auto-transform payloads to DTO class instances
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );
  await app.listen(3000);
}
```

Reference: [NestJS — Validation](https://docs.nestjs.com/techniques/validation)
