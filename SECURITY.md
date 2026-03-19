# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 0.3.x   | Yes       |
| < 0.3   | No        |

## Reporting a Vulnerability

If you discover a security vulnerability in Kavex, **please do not open a public issue.**

### Preferred: GitHub Private Vulnerability Reporting

1. Go to [Security → Advisories](https://github.com/ChiFungHillmanChan/kavex/security/advisories) on this repository.
2. Click **"Report a vulnerability"**.
3. Fill in the details and submit.

### Alternative: Email

Send an email to **ChiFungHillmanChan** via the contact information on the [GitHub profile](https://github.com/ChiFungHillmanChan). Include:

- A description of the vulnerability
- Steps to reproduce
- Affected version(s)
- Any potential impact assessment

## Response Timeline

- **Acknowledgement** — within 48 hours of report
- **Initial assessment** — within 5 business days
- **Fix or mitigation** — as soon as practical, typically within 30 days for confirmed vulnerabilities

## Scope

The following are considered in-scope for security reports:

- Command injection via hook inputs or CLI arguments
- Bypass of dangerous-command blocking (`block-dangerous.sh`)
- Bypass of file-protection rules (`protect-files.sh`)
- Credential or secret exposure through hook output or logs
- Path traversal in `install.sh` or `kavex` CLI

The following are **out of scope**:

- Issues requiring the user to intentionally disable hooks (`kavex deactivate`)
- Social engineering attacks
- Vulnerabilities in upstream dependencies (report those to the respective projects)

## Disclosure

We follow coordinated disclosure. Once a fix is released, we will credit the reporter (unless anonymity is requested) and publish a brief advisory.
