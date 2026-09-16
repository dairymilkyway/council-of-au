---
title: Enforce Ownership Checks to Prevent Horizontal Privilege Escalation
impact: CRITICAL
impactDescription: Missing ownership checks allow any authenticated user to read or modify another user's data
tags: authorization, security, rbac, ownership
---

## Enforce Ownership Checks to Prevent Horizontal Privilege Escalation

**Impact: CRITICAL (missing ownership check = IDOR vulnerability)**

Role guards (e.g., `@Roles('user')`) verify that a request is authenticated and has the right role, but they do not verify that the requesting user owns the resource being accessed. Without an ownership check, any authenticated user with the same role can access any other user's data by guessing an ID.

**Incorrect (role guard present but no ownership check):**

```typescript
// BAD — any authenticated user can read any order by ID
@Get(':id')
@UseGuards(JwtAuthGuard)
async getOrder(@Param('id') id: string) {
  return this.orderService.findById(id);
}
```

**Incorrect (ownership check in controller — wrong layer):**

```typescript
// BAD — authorization logic in controller is untestable and easy to forget
@Get(':id')
@UseGuards(JwtAuthGuard)
async getOrder(@Param('id') id: string, @CurrentUser() user: User) {
  const order = await this.orderService.findById(id);
  if (order.userId !== user.id) throw new ForbiddenException();
  return order;
}
```

**Correct (ownership check in service — testable, consistent):**

```typescript
// GOOD — authorization enforced in the service layer
@Get(':id')
@UseGuards(JwtAuthGuard)
async getOrder(@Param('id') id: string, @CurrentUser() user: User) {
  return this.orderService.findByIdForUser(id, user.id);
}

// In OrderService:
async findByIdForUser(id: string, requestingUserId: string) {
  const order = await this.prisma.order.findUnique({ where: { id } });
  if (!order) throw new NotFoundException('Order not found');
  if (order.userId !== requestingUserId) throw new ForbiddenException();
  return order;
}
```

**Exception (admin bypass):**

```typescript
// GOOD — admins can access any resource; regular users are ownership-checked
async findByIdForUser(id: string, requestingUser: User) {
  const order = await this.prisma.order.findUnique({ where: { id } });
  if (!order) throw new NotFoundException();
  if (requestingUser.role !== Role.ADMIN && order.userId !== requestingUser.id) {
    throw new ForbiddenException();
  }
  return order;
}
```

Reference: [OWASP — Broken Object Level Authorization (BOLA/IDOR)](https://owasp.org/API-Security/editions/2023/en/0xa1-broken-object-level-authorization/)
