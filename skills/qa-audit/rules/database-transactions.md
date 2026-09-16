---
title: Wrap Multi-Step Writes in a Prisma Transaction
impact: CRITICAL
impactDescription: Without transactions, partial failures leave data in an inconsistent state
tags: prisma, database, transactions, data-integrity
---

## Wrap Multi-Step Writes in a Prisma Transaction

**Impact: CRITICAL (partial failure without a transaction corrupts data)**

Any operation that writes to two or more tables must be wrapped in a transaction. If the second write fails without a transaction, the first write persists and the database is left in a corrupt intermediate state.

**Incorrect (sequential writes without a transaction):**

```typescript
// BAD — if createProfile fails, the user is created but has no profile
async createUser(dto: CreateUserDto) {
  const user = await this.prisma.user.create({ data: { email: dto.email } });
  const profile = await this.prisma.profile.create({
    data: { userId: user.id, displayName: dto.name },
  });
  return { user, profile };
}
```

**Correct (interactive transaction — use when later steps depend on earlier results):**

```typescript
// GOOD — atomic: both succeed or both roll back
async createUser(dto: CreateUserDto) {
  return this.prisma.$transaction(async (tx) => {
    const user = await tx.user.create({ data: { email: dto.email } });
    const profile = await tx.profile.create({
      data: { userId: user.id, displayName: dto.name },
    });
    return { user, profile };
  });
}
```

**Correct (batch transaction — use when steps are independent):**

```typescript
// GOOD — two operations submitted in one round-trip
async transferCredits(fromId: string, toId: string, amount: number) {
  await this.prisma.$transaction([
    this.prisma.wallet.update({
      where: { userId: fromId },
      data: { balance: { decrement: amount } },
    }),
    this.prisma.wallet.update({
      where: { userId: toId },
      data: { balance: { increment: amount } },
    }),
  ]);
}
```

Reference: [Prisma — Transactions](https://www.prisma.io/docs/orm/prisma-client/queries/transactions)
