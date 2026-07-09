# Printer Architecture

## Overview

Receipt printers are controlled by the edge device via ESC/POS commands.
All printing is fire-and-forget with a local job queue to handle printer unavailability.

---

## Print queue

Every print request is written to the local `print_queue` table before sending to the printer.
This ensures no ticket is lost if the printer is unavailable at the time of the request.

```sql
CREATE TABLE print_queue (
  id          TEXT PRIMARY KEY,
  order_id    TEXT,
  job_type    TEXT NOT NULL,   -- 'receipt' | 'kitchen' | 'label'
  content     BLOB NOT NULL,   -- precomputed ESC/POS byte sequence
  status      TEXT DEFAULT 'pending',  -- pending | printing | done | failed
  attempts    INTEGER DEFAULT 0,
  created_at  INTEGER NOT NULL,
  printed_at  INTEGER
);
```

---

## Print flow

```text
Order action triggers print
    ↓
Generate ESC/POS byte sequence (in memory)
Write to print_queue with status='pending' (SQLite)
    ↓
Print worker picks up pending jobs
    ↓
Send bytes to printer (TCP or USB)
    ↓
On success: update status='done', printed_at=now()
On failure: increment attempts, status='failed' if attempts > 3
```

The print worker runs every 2 seconds. It processes jobs in `created_at` order.

---

## Printer connection

| Connection type        | When to use               |
| ---------------------- | ------------------------- |
| TCP socket (port 9100) | Network-attached printers |
| USB serial             | Direct-attached printers  |

Connection is opened per print job, then closed. Do not hold a persistent connection
(printers disconnect unexpectedly and do not handle persistent connections reliably).

---

## Error handling

- Printer offline: job stays in queue as `pending`, worker retries every 2s.
- Print error mid-job: job marked `failed`, operator notified in UI.
- After 3 failures: job is flagged, operator must manually retry or dismiss.
- Never silently discard a print job — every failure is logged and visible.

---

## Printer status in UI

Show a printer status indicator to the operator at all times:

- 🟢 Online — last job succeeded
- 🟡 Warning — last job failed, retrying
- 🔴 Offline — cannot reach printer

Status is derived from the last 3 print job results, not from a ping.

---

## Multi-printer setup

Some locations have multiple printers (receipt + kitchen).
Each printer is configured with a `printer_id` and a set of `job_types` it handles.
The print worker routes jobs based on `job_type → printer_id` mapping stored in config.

See `knowledge/escpos.md` for ESC/POS command reference and byte sequences.
