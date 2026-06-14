# Software Lifecycle Prompt Template

## Estructura Completa

```markdown
# ROL
Eres [rol especializado] con experiencia en [dominio específico].

# CONTEXTO
- Sistema: [nombre/descripción]
- Stack: [tecnologías]
- Ubicación: [dónde opera]
- Usuarios: [quiénes lo usan]

# TAREA
[Descripción clara de qué se necesita]

# INPUT
- Tipo: [datos de entrada]
- Formato: [estructura]
- Constraints: [límites]

# OUTPUT
[Formato exacto del resultado]
[Ejemplo concreto]

# PRINCIPIOS DE DISEÑO
1. [Principio arquitectónico]
2. [Principio de calidad]
3. [Principio de rendimiento]

# REQUIREMENTS
- [Requisito funcional 1]
- [Requisito funcional 2]
- [Requisito no funcional 1]

# EDGE CASES
| Caso | Manejo |
|------|--------|
| [Edge case] | [Cómo resolver] |
| [Edge case] | [Cómo resolver] |

# ERROR HANDLING
| Error | Acción |
|-------|--------|
| [Error] | [Manejo] |
| [Error] | [Manejo] |

# SECURITY
- [Constraint de seguridad]
- [Constraint de seguridad]

# TESTING
- [Caso de prueba 1]
- [Caso de prueba 2]

# PRODUCTION
- [Consideración para producción]
- [Consideración para producción]
```

## Secciones Explicadas

### ROL
El rol define el expertise. Uno por prompt, máximo.

### CONTEXTO
Solo incluir lo relevante para la tarea. Evitar Walls of Text.

### TAREA
Un verbo, un objetivo. Sin ambigüedad.

### INPUT/OUTPUT
Definir tipos y formatos. Ejemplos concretos.

### PRINCIPIOS
Máximo 3. Pensar en deuda técnica.

### REQUIREMENTS
Funcionales y no funcionales separados.

### EDGE CASES
Tabla simple. Uno por fila.

### ERROR HANDLING
Qué hacer cuando falla. No fallar silenciosamente.

### SECURITY
No optional. Siempre presente.

### TESTING
Cómo validar que funciona.

### PRODUCTION
Logging, metrics, rollback.

---

## Ejemplo Completo

```markdown
# ROL
Eres un backend engineer Go especializado en APIs REST.

# CONTEXTO
- API de gestión de usuarios
- Go 1.22+, Gin framework
- PostgreSQL 15
- Autenticación JWT

# TAREA
Crear endpoint de login con email/password.

# INPUT
- Body: {"email": "string", "password": "string"}
- Headers: Content-Type: application/json

# OUTPUT
200: {"token": "jwt_token", "expires_at": "timestamp"}
401: {"error": "invalid_credentials"}
422: {"error": "validation_error", "fields": {}}

# PRINCIPIOS DE DISEÑO
1. No guardar passwords en texto plano (bcrypt)
2. Tokens con expiración corta (15min) + refresh
3. Rate limiting implícito (1 request/segundo/IP)

# EDGE CASES
| Caso | Manejo |
|------|--------|
| Email no existe | 401 same msg (timing attack) |
| Password wrong | 401 |
| Rate limit exceeded | 429 |
| DB connection lost | 500 |

# ERROR HANDLING
| Error | Acción |
|-------|--------|
| DB timeout | Log + 500 + retryonce |
| JWT signing fail | Log + 500 + alert |

# SECURITY
- Sanitizar input email (no SQL injection)
- Hash comparison timing-safe
- No exponer user existence en errores
- CORS configured
- Input validation (email format, password min 8)

# TESTING
- Test con credenciales válidas → 200 + token
- Test con password incorrecto → 401
- Test con email inválido → 422
- Test con SQL injection attempt → 422
- Test con rate limit → 429

# PRODUCTION
- Log: login attempts sin passwords
- Metric: login_success_rate
- Alert: >10% failed logins en 5 min
```