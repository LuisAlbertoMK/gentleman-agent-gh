# Cut Tactics — karpathy-loop

## L1: Easy (20-30%)
Delete: filler ("Por supuesto"/"Aquí tienes"/"Claro está") · greetings/signoffs · "step by step" (model does implicitly)
## L2: Medium (30-50%)
Merge redundant sentences → bullets · "clean code, no errors, follow conventions" instead of 3 sentences
Bullet chains → inline: "Validate email/password → hash → save."
Examples → title only: "Ej: {name, email} → validado"
## L3: Advanced (50-70%)
Role → "Python/Django dev." · Constraints → "Regex: [a-z0-9], max 100, trim"
Identity → "Go dev. Implement /endpoint." · Output → "Response: JSON {id, name, email}"

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
