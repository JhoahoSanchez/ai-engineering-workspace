# .env.example Template

Every project must have a `.env.example` at its root.
This file is committed to source control. The real `.env` is NOT.

Rules:

- Every environment variable the app uses must appear here.
- Values in this file are examples or empty — never real secrets.
- Each variable has a comment explaining what it is and where to get it.
- Group related variables together with a section comment.

---

## Template

```bash
# =============================================================================
# Application
# =============================================================================

# Port the server listens on
PORT=3000

# Environment (development | staging | production)
NODE_ENV=development

# Log level (error | warn | info | debug | trace)
LOG_LEVEL=info

# =============================================================================
# Database
# =============================================================================

# Path to the SQLite database file (for SQLite-based projects)
DB_PATH=./data/app.db

# OR: Connection string for PostgreSQL/MySQL
# DATABASE_URL=postgres://user:password@localhost:5432/dbname

# =============================================================================
# Authentication
# =============================================================================

# Secret key for signing JWT tokens — generate with: openssl rand -hex 32
JWT_SECRET=

# JWT access token expiry (e.g. 15m, 1h, 7d)
JWT_EXPIRES_IN=15m

# JWT refresh token expiry
JWT_REFRESH_EXPIRES_IN=7d

# =============================================================================
# Cloud / AWS (if applicable)
# =============================================================================

# AWS region
AWS_REGION=us-east-1

# AWS credentials — use IAM role in production, keys only for local dev
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=

# S3 bucket for uploads/backups
S3_BUCKET=

# =============================================================================
# External integrations (add as needed)
# =============================================================================

# [Service name] API key — obtain from [where to get it]
# [SERVICE]_API_KEY=

# =============================================================================
# Edge device (if applicable)
# =============================================================================

# URL of the cloud API this device syncs to
CLOUD_API_URL=http://localhost:3000

# Device identifier — generated on first run, stored persistently
DEVICE_ID=

# Device authentication token — provisioned from the back office
DEVICE_TOKEN=

# Printer IP address (for network-attached printers)
PRINTER_HOST=192.168.1.100
PRINTER_PORT=9100
```

---

## How to use this template

1. Copy this to your project root as `.env.example`.
2. Add `.env` to `.gitignore` immediately.
3. Remove sections not relevant to your stack.
4. Add any project-specific variables.
5. When a new variable is added to the app, add it here immediately — never let them drift.

Every variable a new developer needs to set up locally must be listed here.
If a developer cannot run the project using only `.env.example` as a guide, it is incomplete.
