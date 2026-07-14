# Compression Examples

## LEAN (default)
```
Q: How does auth work?
A: JWT middleware in middleware.go. Validates token + expiry. Returns 401 if invalid.
```

## ULTRA
```
Q: Auth?
A: middleware.go — JWT validate + expiry → 401.
```

## CAVEMAN
```
Q: auth?
A: middleware.go JWT+expiry→401
```

## Level Quick Reference
| Level | Disclaimers | Examples | Articles | When |
|-------|-------------|----------|----------|------|
| LEAN | ✗ | ✓ | ✓ | Default |
| ULTRA | ✗ | ✗ | ✓ | High context |
| CAVEMAN | ✗ | ✗ | ✗ | Emergency |
