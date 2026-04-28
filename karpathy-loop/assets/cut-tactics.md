# Cut Tactics — karpathy-loop

## Level 1: Easy (20-30% reduction)

### Muletillas a Eliminar
```
REMOVE:
- "Por supuesto que sí,"
- "¡Claro está!"
- "Aquí tienes:"
- "Con gusto,"
- "Sin más preámbulos,"

REPLACE WITH:
- Nothing (delete entirely)
```

### Saludos/Despedidas
```
REMOVE:
- "Hola, ¿cómo estás?"
- "Espero que esto ayude."
- "Saludos,"
- "¡Éxito!"

REPLACE WITH:
- Nothing
```

### Chain of Thought Verbose
```
BEFORE:
"Vamos a pensar esto paso a paso. Primero, necesito entender qué nos piden. Luego, analizaremos cómo resolverlo."

AFTER:
[DELETE ENTIRELY — modelo ya lo hace]
```

## Level 2: Medium (30-50% reduction)

### Fusionar Instrucciones
```
BEFORE:
"Debes asegurarte de que el código esté limpio.
También debes verificar que no haya errores.
Además, necesitas seguir las convenciones del proyecto."

AFTER:
"Clean code, no errors, follow conventions."
```

### Bullet Consolidation
```
BEFORE:
"- Validar email
- Validar password
- Hashear password
- Guardar en DB"

AFTER:
"Validate email/password → hash → save."
```

### Example Optimization
```
BEFORE:
"Por ejemplo, si el usuario ingresa:
{
  'name': 'Juan',
  'email': 'juan@example.com'
}
Entonces el output debería ser..."

AFTER:
"Ejemplo: {name, email} → {name, email: validado}"
```

## Level 3: Advanced (50-70% reduction)

### Template Structures
```
BEFORE:
"Eres un desarrollador de Python. Trabajas con el framework Django.
Tienes 10 años de experiencia. Especializado en APIs REST."

AFTER:
"Python/Django dev."
```

### Constraint Shortcuts
```
BEFORE:
"Constraints:
- Máximo 100 caracteres
- Solo letras y números
- No caracteres especiales
- No espacios al inicio o final"

AFTER:
"Constraints: [a-z0-9], max 100, trim"
```

### Role + Task = Sufficient
```
BEFORE:
"Como desarrollador senior especializado en Go con amplia 
experiencia en sistemas distribuidos, tu responsabilidad 
es implementar el endpoint siguiendo las mejores prácticas..."

AFTER:
"Go dev. Implement /endpoint."
```

### Output Format Shortcuts
```
BEFORE:
"Tu respuesta debe ser en formato JSON con la siguiente estructura:
{
  'id': número entero,
  'name': texto,
  'email': email válido
}
No incluyas campos adicionales."

AFTER:
"Output: JSON {id, name, email}"
```

## Quick Reference Table

| Original | Shortcut | Savings |
|----------|----------|---------|
| "Por supuesto que sí" | [delete] | 100% |
| "Vamos paso a paso" | [delete] | 100% |
| "Debes asegurarte de que" | "debe" | 50% |
| "Por ejemplo" | "ej:" | 50% |
| "Primero...luego...después" | [delete] | 100% |
| "También debes" | "y" | 60% |
| "Además, necesitas" | "y" | 60% |
| "En conclusión" | "→" | 80% |
| "Tu respuesta debe ser" | "Response:" | 70% |