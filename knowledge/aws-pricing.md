# AWS Pricing Reference

> Prices are approximate as of 2024 (us-east-1). Verify at https://aws.amazon.com/pricing
> before making infrastructure decisions.

---

## Compute

### EC2 (on-demand, us-east-1)

| Instance  | vCPU | RAM  | $/hour  | $/month |
| --------- | ---- | ---- | ------- | ------- |
| t3.micro  | 2    | 1 GB | $0.0104 | ~$7.50  |
| t3.small  | 2    | 2 GB | $0.0208 | ~$15    |
| t3.medium | 2    | 4 GB | $0.0416 | ~$30    |
| t3.large  | 2    | 8 GB | $0.0832 | ~$60    |

Reserved instances (1-year, no upfront): ~40% discount.

### Lambda

- First 1M requests/month: free
- $0.0000002/request after that
- Duration: $0.0000166667 per GB-second
- **Good for**: low-traffic APIs, background jobs, event processors

---

## Database

### RDS MySQL/PostgreSQL (db.t3.micro)

- $0.017/hour → ~$12/month
- Storage: $0.115/GB-month

### Aurora Serverless v2

- $0.12/ACU-hour (min 0.5 ACU)
- **Good for**: variable workloads, dev/test, early-stage products
- Min cost: ~$43/month if always on at 0.5 ACU

### SQLite on EC2

- No additional cost beyond EC2 + EBS storage
- EBS gp3: $0.08/GB-month
- **For this project**: SQLite on EC2 is the recommended starting point

---

## Storage

### S3

- Standard storage: $0.023/GB-month
- Requests: $0.0004 per 1000 PUT, $0.0004 per 10,000 GET
- Data transfer out: $0.09/GB (first 10TB)

### EBS (gp3)

- $0.08/GB-month
- 3,000 IOPS and 125 MB/s included at no extra cost

---

## Networking

### Data transfer out (from AWS)

- First 100 GB/month: $0.09/GB
- Next 9.9 TB: $0.085/GB
- **Inbound to AWS is free**

### API Gateway (HTTP API)

- First 300M requests: $1.00/million
- After: $0.90/million

### CloudFront

- First 10 TB: $0.0085/GB (cheaper than direct EC2 egress)
- Use for: static assets, any response that can be cached

---

## Cost estimation template

```
# Monthly estimate for N edge devices

Compute (API backend):
  EC2 t3.small × 1: ~$15/month

Database:
  SQLite on EBS 20GB: ~$1.60/month

Networking:
  N devices × avg_events/day × avg_event_size_bytes × 30 days → X GB
  X GB × $0.09 → $__/month

Monitoring:
  CloudWatch Logs (5GB ingested): ~$2.50/month
  CloudWatch alarms: $0.10/alarm/month

Total estimate: $__/month
```

---

## Cost optimization levers

1. Use EC2 reserved instances at 5+ devices (40% savings).
2. Use CloudFront for the Vue app static assets (S3 + CloudFront < EC2 egress).
3. Batch sync events (50 per request) vs 1-at-a-time (50× fewer API Gateway calls).
4. Set CloudWatch log retention to 30 days (default is indefinite).
5. Use S3 Lifecycle rules: move logs to Glacier after 30 days.
