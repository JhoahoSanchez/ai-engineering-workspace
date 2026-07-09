# AWS Cost Architecture

> Fill in actual numbers from `knowledge/aws-pricing.md` once the stack is finalized.
> This file captures design decisions made to control costs.

---

## Cost-aware design principles

1. **Edge-heavy, cloud-light**: run as much as possible on the edge device.
   Every API call to the cloud costs money (compute + bandwidth). Local SQLite reads are free.

2. **Batch, don't stream**: sync events in batches (up to 50), not one-by-one.
   Reduces API Gateway invocations and Lambda cold starts if using serverless.

3. **Compress payloads**: JSON event batches should be gzip-compressed if > 1KB.

4. **WebSocket over polling**: one persistent WS connection per device is cheaper
   than polling an HTTP endpoint every N seconds.

---

## Services and cost drivers

| Service      | Use              | Cost driver         | Mitigation                                            |
| ------------ | ---------------- | ------------------- | ----------------------------------------------------- |
| EC2 / ECS    | API backend      | Instance hours      | Right-size; use reserved instances at scale           |
| RDS / Aurora | Cloud DB         | Instance + storage  | Use Aurora Serverless v2 at low scale                 |
| API Gateway  | REST endpoints   | Per-request         | Batch events, avoid chatty APIs                       |
| CloudFront   | Static assets    | Data transfer       | Cache aggressively                                    |
| S3           | Backups, exports | Storage + requests  | Lifecycle rules to Glacier after 30 days              |
| CloudWatch   | Logging          | Ingestion + storage | Log only structured logs, avoid verbose debug in prod |

---

## Estimated cost per device per month

<!-- Fill in once stack is confirmed and usage estimated.
     Base your estimate on: events per day × avg payload × upload frequency -->

| Tier    | Devices | Est. monthly AWS cost |
| ------- | ------- | --------------------- |
| Starter | 1–5     | $\_\_                 |
| Growth  | 5–20    | $\_\_                 |
| Scale   | 20–100  | $\_\_                 |

---

## Cost alerts

Set a CloudWatch billing alert at $50 and $200.
Never run without billing alerts configured — unexpected traffic spikes happen.
