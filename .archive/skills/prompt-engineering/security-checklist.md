# Security Checklist — Prompt Engineering

## Pre-Flight (Antes de Crear el Prompt)

```
□ ¿El prompt maneja input del usuario?
□ ¿El output se ejecuta/evalúa?
□ ¿Se exponen datos sensibles?
□ ¿Hay APIs externas involcradas?
□ ¿Se guardan datos?
```

## Input Validation

```
INPUT VALIDATION:
□ Tipos de datos especificados
□ Rangos válidos definidos
□ Longitudes máximas establecidas
□ Formatos validados (email, URL, etc.)
□ Caracteres especiales manejados
□ Null/empty handling
□ Type coercion segura
```

## Output Handling

```
OUTPUT HANDLING:
□ Output no se ejecuta automáticamente
□ JSON/HTML/SQL injection prevenido
□ Longitudes de output limitadas
□ Sanitización de output si se muestra
□ Rate limiting implícito
□ Timeout en respuestas largas
```

## Data Protection

```
DATA PROTECTION:
□ No hardcodear credenciales
□ No loguear datos sensibles
□ No exponer IDs internos
□ Tokens/keys no en output
□ Datos personales anonimizados en logs
□ PII handling correcto
```

## Injection Prevention

```
INJECTION PREVENTION:
□ Prompt injection: input nunca como prompt
□ SQL injection: parameterized queries
□ Code injection: sandbox/eval limitado
□ HTML injection: escape output
□ Command injection: no shell exec de user input
```

## Errors & Failures

```
ERROR HANDLING:
□ Fallos seguros (fail closed)
□ Errores genéricos al usuario
□ Logging detallado interno
□ No stack traces en producción
□ Timeouts en todo
□ Retry policies definidas
```

## Compliance

```
COMPLIANCE:
□ GDPR considerations (si aplica)
□ Rate limits documentados
□ Data retention policy
□ Audit trail ( quién, qué, cuándo)
□ Consentimiento de usuario (si aplica)
```

## Template Rápido de Seguridad

```markdown
# SECURITY
- Input: [validación explícita]
- Sanitización: [qué se sanitiza]
- Límites: [rate limit, size limits]
- Errores: [fail safely]
- Logging: [sin datos sensibles]
- Output: [no ejecutar sin validación]
```

## Quick Check

```bash
# Verificar que no hay secrets en el prompt
grep -iE "password|secret|api.key|token" prompt.txt && echo "⚠️ Secrets found!"
```

## Resources

- OWASP Top 10: https://owasp.org/www-project-top-ten/
- CWE Top 25: https://cwe.mitre.org/top25/
