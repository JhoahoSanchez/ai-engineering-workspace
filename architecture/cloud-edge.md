# Cloud-Edge Architecture

## System overview

```text
┌─────────────────────────────────────────┐
│               AWS Cloud                 │
│                                         │
│  ┌──────────┐     ┌──────────────────┐  │
│  │  REST API │     │  WebSocket Server│  │
│  │ (backend) │     │  (real-time hub) │  │
│  └─────┬────┘     └────────┬─────────┘  │
│        │                   │            │
│  ┌─────▼───────────────────▼─────────┐  │
│  │           Cloud Database           │  │
│  └────────────────────────────────────┘  │
└─────────────────┬───────────────────────┘
                  │  HTTPS + WSS
        ┌─────────▼──────────┐
        │    Edge Device     │
        │  (POS Terminal)    │
        │                    │
        │  ┌──────────────┐  │
        │  │  Local App   │  │
        │  │  (Go)        │  │
        │  └──────┬───────┘  │
        │         │          │
        │  ┌──────▼───────┐  │
        │  │  SQLite DB   │  │
        │  └──────────────┘  │
        │                    │
        │  ┌──────────────┐  │
        │  │   Printer    │  │
        │  │  (ESC/POS)   │  │
        │  └──────────────┘  │
        └────────────────────┘
```

---

## Responsibilities

### Cloud (backend)

- Master data store (menus, tenants, configuration)
- Business reporting and analytics
- Multi-tenant account management
- Receives and validates sync events from edge
- Pushes configuration updates to edge via WebSocket

### Edge (local device)

- All point-of-sale operations (orders, payments, printing)
- Local SQLite as operational store
- Sync queue for event upload to cloud
- Printer control via ESC/POS over USB or network

---

## Communication protocols

| Direction      | Protocol                 | Use case                              |
| -------------- | ------------------------ | ------------------------------------- |
| Edge → Cloud   | HTTPS REST               | Sync event upload, auth               |
| Cloud → Edge   | WebSocket                | Real-time menu updates, config pushes |
| Edge ↔ Printer | TCP socket or USB serial | ESC/POS print commands                |

---

## Deployment model

Each physical location has one or more edge devices.
Each edge device is independently operational — no edge device depends on another.
Cloud is shared (multi-tenant or single-tenant depending on `context.md`).

---

## Security boundary

- Edge devices authenticate to the cloud with a device token (not user credentials).
- Device tokens are scoped to a specific tenant and location.
- All cloud communication is over HTTPS/WSS — no plain HTTP.
- The edge device does not expose any network port to the local network
  (printer communication is outbound only).
