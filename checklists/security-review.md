# Security Review Checklist

Used by the security subagent when reviewing changes that involve auth, user data,
external inputs, payments, or infrastructure. Also useful as a self-check before
submitting any security-sensitive PR.

---

## Input validation

- [ ] All external inputs are validated before any logic runs
      (HTTP body, query params, headers, path params, file contents, WebSocket messages)
- [ ] Validation uses a schema library (Zod, Joi, etc.) — not manual if/else checks
- [ ] Validation errors return 400 with a clear message, not 500 or a crash
- [ ] String inputs have max length limits
- [ ] Numeric inputs have min/max bounds where applicable
- [ ] File uploads: type, size, and content are validated

## Authentication

- [ ] Endpoints that require auth have auth middleware applied
- [ ] Auth middleware is applied in the right place (router level, not per-handler copy-paste)
- [ ] Tokens have appropriate expiry (short for access tokens, longer for refresh)
- [ ] Token validation errors return 401, not 500
- [ ] No authentication logic is duplicated — it is centralized in middleware

## Authorization

- [ ] Every operation that reads or modifies data checks that the caller owns it
      (`WHERE tenant_id = ? AND id = ?`, not just `WHERE id = ?`)
- [ ] Authorization is checked in the service layer, not only the route layer
      (so it is enforced regardless of how the service is called)
- [ ] Privilege escalation is prevented: a user cannot act as another user or tenant
- [ ] Admin-only operations have an explicit role check

## Secrets and sensitive data

- [ ] No secrets, API keys, or passwords are hardcoded or in source control
- [ ] `process.env` is only accessed through the typed config module
- [ ] Sensitive fields (passwords, tokens, card data) are not returned in API responses
- [ ] Sensitive fields are not logged at any level
- [ ] Passwords are hashed with bcrypt (cost ≥ 12) or equivalent — never MD5/SHA1/plain

## Injection

- [ ] SQL: all queries use parameterized statements (no string concatenation)
- [ ] Shell commands: no user input is interpolated into shell commands
      (use argument arrays, not string interpolation)
- [ ] Path traversal: file paths built from user input are sanitized
      (`path.resolve` + verify it stays within expected directory)
- [ ] Template injection: user input is not rendered as code or template expressions

## Transport

- [ ] All communication uses HTTPS/WSS in production (not HTTP)
- [ ] Sensitive data is not in URL parameters (visible in logs and browser history)
- [ ] CORS is configured restrictively (not `origin: '*'` in production)
- [ ] Security headers are set: CSP, X-Content-Type-Options, X-Frame-Options, HSTS

## Dependencies

- [ ] `pnpm audit` (or `npm audit`) shows no HIGH or CRITICAL CVEs
- [ ] New dependencies are necessary (not adding a dep for a trivial operation)
- [ ] New dependencies have reasonable download counts and maintenance status

## Logging and monitoring

- [ ] Authentication failures are logged (for intrusion detection)
- [ ] Authorization failures are logged with context (tenantId, userId, resource)
- [ ] Rate limiting is in place for login and token endpoints

---

## Finding format (for security subagent report)

```text
[CRITICAL/HIGH/MEDIUM/LOW] — [Short title]
Location: file.ts:line
Description: [what the vulnerability is]
Risk: [what an attacker could do]
Fix: [specific recommended fix]
```
