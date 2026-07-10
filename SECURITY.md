# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| latest  | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability within Gentleman Agent, please send an email to the repository owner. All security vulnerabilities will be promptly addressed.

**Please do NOT report security vulnerabilities through public GitHub issues.**

### What to include

- Type of issue (e.g., buffer overflow, SQL injection, cross-site scripting, etc.)
- Full paths of source file(s) related to the manifestation of the issue
- The location of the affected source code (tag/branch/commit or direct URL)
- Any special configuration required to reproduce the issue
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit it

### Response timeline

- **Acknowledgment**: within 48 hours
- **Assessment**: within 1 week
- **Fix**: depends on severity, typically within 2 weeks

## Security Best Practices

This project manages AI agent configurations and scripts. Key security considerations:

- **Secrets**: Never commit API keys, tokens, or credentials. Use environment variables.
- **Scripts**: All PowerShell scripts go through PSSA analysis before commit.
- **MCP Servers**: MCP configurations are validated for injection patterns.
- **Dependencies**: Dependabot monitors for vulnerable dependencies.
