# ESC/POS Reference

ESC/POS (Escape/Point of Sale) is the command language used by most thermal receipt printers.
Commands are binary byte sequences sent over TCP (port 9100) or USB serial.

---

## Key commands

```typescript
const ESC = 0x1b;
const GS = 0x1d;
const FS = 0x1c;
const DLE = 0x10;

const Commands = {
  // Initialization
  INIT: Buffer.from([ESC, 0x40]),

  // Text formatting
  BOLD_ON: Buffer.from([ESC, 0x45, 0x01]),
  BOLD_OFF: Buffer.from([ESC, 0x45, 0x00]),
  UNDERLINE_ON: Buffer.from([ESC, 0x2d, 0x01]),
  UNDERLINE_OFF: Buffer.from([ESC, 0x2d, 0x00]),
  DOUBLE_HEIGHT_ON: Buffer.from([GS, 0x21, 0x11]),
  DOUBLE_HEIGHT_OFF: Buffer.from([GS, 0x21, 0x00]),

  // Alignment
  ALIGN_LEFT: Buffer.from([ESC, 0x61, 0x00]),
  ALIGN_CENTER: Buffer.from([ESC, 0x61, 0x01]),
  ALIGN_RIGHT: Buffer.from([ESC, 0x61, 0x02]),

  // Line feed and cut
  LINE_FEED: Buffer.from([0x0a]),
  FEED_AND_CUT: Buffer.from([GS, 0x56, 0x41, 0x03]), // partial cut after 3 lines
  FULL_CUT: Buffer.from([GS, 0x56, 0x00]),
};
```

---

## Building a receipt

Concatenate `Buffer` chunks in order. Send the resulting buffer to the printer in one write.

```typescript
function buildReceipt(order: Order, tenant: Tenant): Buffer {
  const chunks: Buffer[] = [];
  const push = (...bufs: Buffer[]) => chunks.push(...bufs);
  const text = (s: string) => Buffer.from(s, "utf8");
  const line = (s: string) => Buffer.concat([text(s), Commands.LINE_FEED]);
  const blankLine = () => Commands.LINE_FEED;

  push(Commands.INIT);

  // Header
  push(Commands.ALIGN_CENTER, Commands.BOLD_ON, Commands.DOUBLE_HEIGHT_ON);
  push(line(tenant.name));
  push(Commands.DOUBLE_HEIGHT_OFF, Commands.BOLD_OFF);
  push(line(tenant.address ?? ""));
  push(blankLine());

  // Order info
  push(Commands.ALIGN_LEFT);
  push(line(`Order #${order.id.slice(-6).toUpperCase()}`));
  push(line(`Date: ${formatDate(order.closedAt!)}`));
  push(line(`Operator: ${order.operatorId}`));
  push(blankLine());

  // Items
  push(line("--------------------------------"));
  for (const item of order.items.filter((i) => i.status === "active")) {
    const left = `${item.quantity}x ${item.name}`;
    const right = formatCurrency(item.unitPrice * item.quantity);
    push(line(padLine(left, right, 32))); // 32 chars wide (common for 58mm paper)
  }
  push(line("--------------------------------"));

  // Totals
  push(line(padLine("Subtotal", formatCurrency(order.subtotal), 32)));
  push(line(padLine("Tax", formatCurrency(order.tax), 32)));
  if (order.discount > 0) {
    push(line(padLine("Discount", `-${formatCurrency(order.discount)}`, 32)));
  }
  push(Commands.BOLD_ON);
  push(line(padLine("TOTAL", formatCurrency(order.total), 32)));
  push(Commands.BOLD_OFF);
  push(blankLine());

  // Footer
  push(Commands.ALIGN_CENTER);
  push(line("Thank you!"));
  push(blankLine(), blankLine());

  push(Commands.FEED_AND_CUT);

  return Buffer.concat(chunks);
}

function padLine(left: string, right: string, width: number): string {
  const spaces = width - left.length - right.length;
  return left + " ".repeat(Math.max(1, spaces)) + right;
}
```

---

## Paper widths

| Paper | Printable chars (12pt) |
| ----- | ---------------------- |
| 58mm  | ~32 characters         |
| 80mm  | ~42–48 characters      |

Always check `tenant.printerPaperWidth` from config before building receipts.
Do not hardcode 32 — use a constant from config.

---

## Sending to printer

```typescript
import net from "net";

async function sendToPrinter(
  host: string,
  port: number,
  data: Buffer,
): Promise<void> {
  return new Promise((resolve, reject) => {
    const socket = new net.Socket();
    const timeout = setTimeout(() => {
      socket.destroy();
      reject(new Error("Printer connection timeout"));
    }, 5000);

    socket.connect(port, host, () => {
      socket.write(data, (err) => {
        clearTimeout(timeout);
        socket.end();
        if (err) reject(err);
        else resolve();
      });
    });

    socket.on("error", (err) => {
      clearTimeout(timeout);
      reject(err);
    });
  });
}
```

Open a new socket per job. Do not reuse connections — printers drop idle connections
unpredictably.

---

## Character encoding

Thermal printers typically use Code Page 437 or ISO-8859-1, not UTF-8.
For Spanish/Latin characters (accents, ñ), you may need to:

1. Set the code page explicitly: `Buffer.from([ESC, 0x74, 0x10])` (CP437)
2. Or use a library like `iconv-lite` to transcode the string before sending.

Test accented characters on the actual printer model in use — encoding support varies.
