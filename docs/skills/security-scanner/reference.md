# security-scanner — Reference Materials

> **Externalized from** .agents/skills/security-scanner/SKILL.md to keep the skill under the
> 2KB token budget (ADR-007). Contains worked examples, test steps, and edge cases.

## EXAMPLES

**1. Secrets — regex + trufflehog**: grep → trufflehog:
`grep -rnE "sk-<20+ALNUM>|<PRIVATE_KEY_HEREDOC>" --include="*.{js,ts,py,go,sh}"` then `trufflehog filesystem . --only-verified`

**2. Injection — SQLi/XSS**:
`grep -rnE "SELECT .*\+|WHERE .*\$|execute\(.*\+" --include="*.{js,ts,py,go}"` → parameterize. XSS: `grep -rnE "innerHTML\s*=|dangerouslySetInnerHTML" --include="*.{js,ts}"` → escape output.

**3. Dep vuln CI — dependabot/npm audit**: `.github/dependabot.yml` npm weekly; gate: `npm audit --audit-level=high || exit 1`

**4. Supply chain — sigstore/cosign**: `cosign verify-blob --signature img.sig --cert img.pem artifact.tar.gz` · `curl -fsSL <url> | sha256sum -c checksums.txt`

## TESTING

**1. FP reduction**: fixtures (`<TEST_FIXTURE>`) vs real secrets → flags only real ones.

**2. Zero-secret CI gate**: `trufflehog filesystem . --only-verified --fail` + `! grep -rnE "sk-<20+ALNUM>" .` → blocks merge.

## EDGE CASES

- **FP secrets**: test fixtures, example.com keys, config samples → exclude by path, not value
- **Encrypted vars**: .env.enc / age / sops → scan ciphertext; never decrypt
- **CI secrets vs leaks**: `<SECRETS_PLACEHOLDER>` = legit ref; committed raw value = leak
- **Timing**: pre-commit = fast per-diff; CI = full history; run both