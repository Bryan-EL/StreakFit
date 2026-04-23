# Security Policy

## Supported Versions

| Version | Supported |
|---|---|
| 1.1.x | ✅ |
| 1.0.x | ✅ (critical fixes only) |

## Reporting a Vulnerability

Please **do not** open a public GitHub issue for security vulnerabilities.

Instead, email the maintainers directly or open a [private security advisory](../../security/advisories/new) on GitHub.

Include:
- A description of the vulnerability
- Steps to reproduce
- Potential impact
- Any suggested fix

You will receive a response within 72 hours. If the issue is confirmed, a patch will be released as soon as possible and you will be credited in the changelog unless you prefer to remain anonymous.

## Known Limitations

StreakFit is designed as a local/personal-use application. Be aware of the following before deploying publicly:

- **Flat-file storage** — `users.json` is read and written on every request. It is not suitable for high concurrency or large user bases. Use a proper database for production.
- **Secret key** — The default `app.secret_key` in `app.py` is hardcoded for development. Always override it with a strong random value via environment variable before deploying.
- **No rate limiting** — The auth endpoints have no brute-force protection. Add Flask-Limiter or a reverse proxy rule for public deployments.
- **HTTP only** — Always serve behind HTTPS in production (e.g. via Nginx + Let's Encrypt).
- **Simulated payments** — The gem purchase flow is a demo; no real payment processing occurs.
- **Program access** — Program access is time-based (7 days) and stored as plaintext expiry dates. For high-security deployments, consider moving to a token-based system with server-side validation.