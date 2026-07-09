# WebSocket Patterns

> For the architectural role of WebSockets in this system, see `architecture/websocket.md`.
> This file covers implementation patterns.

---

## Server-side (Node.js with `ws`)

```typescript
import { WebSocketServer, WebSocket } from "ws";
import { IncomingMessage } from "http";

interface DeviceConnection {
  ws: WebSocket;
  deviceId: string;
  tenantId: string;
  lastSeq: number;
}

const connections = new Map<string, DeviceConnection>(); // deviceId → connection

const wss = new WebSocketServer({ noServer: true });

// Attach to existing HTTP server (share port)
server.on("upgrade", (req, socket, head) => {
  const token = extractToken(req);
  const device = verifyDeviceToken(token); // throws if invalid

  wss.handleUpgrade(req, socket, head, (ws) => {
    wss.emit("connection", ws, req, device);
  });
});

wss.on(
  "connection",
  (ws: WebSocket, req: IncomingMessage, device: DeviceIdentity) => {
    const conn: DeviceConnection = {
      ws,
      deviceId: device.id,
      tenantId: device.tenantId,
      lastSeq: 0,
    };

    connections.set(device.id, conn);

    ws.on("message", (data) => handleMessage(conn, data));
    ws.on("close", () => connections.delete(device.id));
    ws.on("error", (err) => {
      logger.error({ deviceId: device.id, err }, "WebSocket error");
      connections.delete(device.id);
    });
  },
);
```

---

## Sending messages to a device

```typescript
let globalSeq = 0; // in production, persist this per tenant in DB

function pushToDevice(
  deviceId: string,
  type: string,
  payload: unknown,
): boolean {
  const conn = connections.get(deviceId);
  if (!conn || conn.ws.readyState !== WebSocket.OPEN) return false;

  const message = JSON.stringify({
    seq: ++globalSeq,
    type,
    payload,
  });

  conn.ws.send(message);
  return true;
}

// Broadcast to all devices of a tenant
function pushToTenant(tenantId: string, type: string, payload: unknown): void {
  for (const conn of connections.values()) {
    if (conn.tenantId === tenantId) {
      pushToDevice(conn.deviceId, type, payload);
    }
  }
}
```

---

## Client-side (edge device)

```typescript
class DeviceSocket {
  private ws: WebSocket | null = null;
  private reconnectAttempt = 0;
  private lastSeq = 0;

  connect(url: string, token: string): void {
    this.ws = new WebSocket(`${url}?token=${token}`);

    this.ws.onopen = () => {
      this.reconnectAttempt = 0;
      logger.info("WebSocket connected");
      this.requestMissedMessages();
    };

    this.ws.onmessage = ({ data }) => {
      const msg = JSON.parse(data as string);
      if (msg.seq !== this.lastSeq + 1) {
        // Gap detected — request replay
        this.requestMissedMessages();
        return;
      }
      this.lastSeq = msg.seq;
      this.dispatch(msg.type, msg.payload);
    };

    this.ws.onclose = () => this.scheduleReconnect(url, token);
    this.ws.onerror = (err) => logger.warn({ err }, "WebSocket error");
  }

  private scheduleReconnect(url: string, token: string): void {
    const delay = Math.min(1000 * 2 ** this.reconnectAttempt, 60_000);
    this.reconnectAttempt++;
    setTimeout(() => this.connect(url, token), delay);
  }

  private requestMissedMessages(): void {
    // Send lastSeq so server can replay
    this.ws?.send(JSON.stringify({ type: "catchup", lastSeq: this.lastSeq }));
  }

  private dispatch(type: string, payload: unknown): void {
    const handlers: Record<string, (p: unknown) => void> = {
      "menu.updated": (p) => handleMenuUpdate(p),
      "price.updated": (p) => handlePriceUpdate(p),
      "config.updated": (p) => handleConfigUpdate(p),
      "device.ping": () =>
        this.ws?.send(JSON.stringify({ type: "device.pong" })),
    };
    handlers[type]?.(payload) ??
      logger.warn({ type }, "Unknown WS message type");
  }
}
```

---

## Heartbeat (keep-alive)

Many load balancers and proxies close idle WebSocket connections after 60–90 seconds.
Send a ping every 30 seconds:

```typescript
// Server-side
setInterval(() => {
  for (const conn of connections.values()) {
    if (conn.ws.readyState === WebSocket.OPEN) {
      conn.ws.ping(); // ws library built-in ping/pong
    }
  }
}, 30_000);
```

The `ws` library handles pong responses automatically. Dead connections are cleaned up
when the next send fails.
