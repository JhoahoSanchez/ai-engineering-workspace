# Business Domain Knowledge

Core entities, lifecycle rules, and business logic for a business POS system.

---

## Core entities

### Order

The central entity. An order groups all items consumed at one table session or in one transaction.

```typescript
interface Order {
  id: string;
  tenantId: string;
  deviceId: string;
  tableId: string | null; // null for takeout/delivery
  type: "dine-in" | "takeout" | "delivery";
  status: OrderStatus;
  items: OrderItem[];
  subtotal: number; // sum of items before tax/discount
  tax: number;
  discount: number;
  total: number; // subtotal + tax - discount
  operatorId: string; // who opened the order
  openedAt: number; // Unix ms
  closedAt: number | null;
}

type OrderStatus = "open" | "closed" | "voided" | "pending-payment";
```

### Order Item

A single menu item within an order, captured at the price at time of ordering.

```typescript
interface OrderItem {
  id: string;
  orderId: string;
  menuItemId: string;
  name: string; // snapshot — menu name at time of order
  quantity: number;
  unitPrice: number; // snapshot — price at time of order
  modifiers: ItemModifier[];
  note: string | null;
  status: "active" | "voided";
  addedAt: number;
}
```

**Important**: `name` and `unitPrice` are snapshots. If the menu changes after an item
is added, the order retains the original price and name. Never join to the menu table
to get order item prices — use the snapshot.

### Menu Item

The catalog of sellable products. Managed from the back office, synced to the edge.

```typescript
interface MenuItem {
  id: string;
  tenantId: string;
  categoryId: string;
  name: string;
  description: string | null;
  price: number;
  isAvailable: boolean;
  printTarget: "receipt" | "kitchen" | "both";
  modifierGroups: ModifierGroup[];
}
```

### Table

Physical or logical table in the dining room.

```typescript
interface Table {
  id: string;
  tenantId: string;
  number: string; // display label, e.g. "Mesa 5", "Bar 2"
  capacity: number;
  status: "available" | "occupied" | "reserved";
  currentOrderId: string | null;
}
```

---

## Order lifecycle

```text
[open]
  ↓ items added/removed
  ↓ payment requested
[pending-payment]
  ↓ payment confirmed
[closed]

From [open] → [voided]   (operator action, requires reason)
From [pending-payment] → [open]   (payment cancelled)
```

**Rules**:

- An order can only be `voided` while in `open` status. Closed orders cannot be voided.
- A table can only have one `open` or `pending-payment` order at a time.
- Voiding an item within an open order changes item status to `voided`, not deletes it.
  (audit trail — deletions are not allowed in order history)
- Total is always recalculated server-side, never trusted from the client.

---

## Payment

```typescript
interface Payment {
  id: string;
  orderId: string;
  method: "cash" | "card" | "transfer" | "other";
  amount: number; // amount tendered
  change: number; // amount returned (cash only)
  tip: number;
  processedAt: number;
  operatorId: string;
}
```

An order can have multiple partial payments (split bill), but the sum of payment amounts
must equal `order.total + tip` for the order to be considered fully paid.

---

## Printing rules

When an order is closed:

1. Print a **receipt** for the customer (full order summary, payment, totals).

When items are added to an open order: 2. Print a **kitchen ticket** for items with `printTarget: 'kitchen'` or `'both'`.
Kitchen tickets go to the kitchen printer, not the customer printer.

Receipts and kitchen tickets are separate print jobs sent to different printers.
See `architecture/printer.md` for the routing logic.

---

## Tax calculation

Tax is applied to the subtotal after discounts:

```text
subtotal = sum(item.unitPrice * item.quantity) for active items
discounted_subtotal = subtotal - discount
tax = discounted_subtotal * tax_rate
total = discounted_subtotal + tax
```

Tax rate is configured per tenant and location. Never hardcode a tax rate.

---

## Glossary

| Term         | Meaning                                                                  |
| ------------ | ------------------------------------------------------------------------ |
| Cover        | One seated customer                                                      |
| Check / Bill | The receipt given to the customer                                        |
| Void         | Cancel an item or order (leaves an audit record)                         |
| Comp         | Mark an item as complimentary (zero price)                               |
| Split        | Divide one order into multiple payments                                  |
| Tender       | The act of accepting payment                                             |
| Modifier     | Optional customization of a menu item (e.g. "no onions", "extra cheese") |
