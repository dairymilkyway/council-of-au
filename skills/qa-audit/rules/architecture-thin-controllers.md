---
title: Keep Controllers Thin — Business Logic Belongs in Services
impact: HIGH
impactDescription: Fat controllers are untestable, duplicate logic across routes, and violate single responsibility
tags: architecture, nestjs, controllers, services
---

## Keep Controllers Thin — Business Logic Belongs in Services

**Impact: HIGH (fat controllers cannot be unit tested and lead to logic duplication)**

Controllers are responsible for HTTP concerns only: parsing the request, calling a service, and returning the response. Any business logic placed in a controller cannot be reused from other entry points (queues, scheduled tasks, WebSocket handlers) and is difficult to unit test in isolation.

**Incorrect (business logic inside the controller):**

```typescript
// BAD — validation, DB access, and transformation all in controller
@Post('checkout')
@UseGuards(JwtAuthGuard)
async checkout(@Body() dto: CheckoutDto, @CurrentUser() user: User) {
  const cart = await this.prisma.cart.findUnique({
    where: { userId: user.id },
    include: { items: { include: { product: true } } },
  });
  if (!cart || cart.items.length === 0) {
    throw new BadRequestException('Cart is empty');
  }
  const total = cart.items.reduce((sum, item) => sum + item.product.price * item.quantity, 0);
  const order = await this.prisma.order.create({
    data: { userId: user.id, total, items: { create: cart.items.map(...) } },
  });
  await this.prisma.cart.delete({ where: { userId: user.id } });
  return order;
}
```

**Correct (controller delegates entirely to service):**

```typescript
// GOOD — controller handles only HTTP: parsing, calling service, returning result
@Post('checkout')
@UseGuards(JwtAuthGuard)
async checkout(@Body() dto: CheckoutDto, @CurrentUser() user: User) {
  return this.orderService.checkout(user.id, dto);
}

// In OrderService — testable, reusable:
async checkout(userId: string, dto: CheckoutDto) {
  const cart = await this.prisma.cart.findUnique({ ... });
  if (!cart || cart.items.length === 0) throw new BadRequestException('Cart is empty');
  const total = cart.items.reduce((sum, item) => sum + item.product.price * item.quantity, 0);
  return this.prisma.$transaction(async (tx) => {
    const order = await tx.order.create({ ... });
    await tx.cart.delete({ where: { userId } });
    return order;
  });
}
```

Reference: [NestJS — Controllers](https://docs.nestjs.com/controllers)
