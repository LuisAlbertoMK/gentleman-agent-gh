# auth-hardening - Reference Materials

> **Externalized from** .agents/skills/auth-hardening/SKILL.md to keep the skill under the 2KB token budget (ADR-007).

## EXAMPLES (6 real grep commands)
JWT alg=none: `grep -rn "algorithm.*['\"]none['\"]" --include="*.ts"`
Hardcoded secret: `grep -rn "secret\s*=\s*['\"][^'\"]+['\"]" --include="*.ts" | grep -v process.env`
OAuth no PKCE: `grep -rn "authorization_code" --include="*.ts" | grep -v code_verifier`
Role after fetch: `grep -B3 "find.*User" --include="*.ts" | grep -v "authorize\|canAccess"`
No HttpOnly: `grep -rn "cookie.*httpOnly.*false" --include="*.ts"`
Weak hashing: `grep -rn "md5\|sha1" --include="*.ts" | grep -v "_test\|checksum"`


## EDGE CASES (4)
MFA bypass: backup codes / recovery often skip rate limits → audit separately
CORS + auth: `Access-Control-Allow-Origin: *` + credentials → browser rejects; must echo origin
Refresh reuse: same token accepted twice → revoke ALL sessions on reuse
When NOT: stateless APIs→no sessions; serverless cold starts→avoid DB sessions; high-throughput internal→prefer mTLS over JWT
