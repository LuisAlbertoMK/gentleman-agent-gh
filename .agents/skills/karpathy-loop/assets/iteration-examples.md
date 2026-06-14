# Karpathy Loop Iteration Examples

## Complete Loop Example: API Handler

### Iteration 0 — Initial (150 tokens)
```
"Você é um desenvolvedor backend Python com mais de 15 anos 
de experiência, especializado em APIs REST com FastAPI. Sua 
tarefa é criar um endpoint de POST para /users que receba 
dados de usuário, valide-os according to business rules, 
armazene no banco de dados PostgreSQL usando SQLAlchemy, 
e retorne o usuário criado com status 201. Você deve seguir 
as melhores práticas de segurança incluindo validação de 
input, sanitização de dados, e tratamento de erros adequado. 
Também deve escrever testes unitários com pytest cobrindo 
mínimo 80% de coverage. Por favor, implemente tudo em código 
Python limpo e bem documentado seguindo padrões PEP 8."
```
Score: 9/10 | Tokens: ~150

### Iteration 1 — After Easy Cuts (65 tokens)
```
"Dev Python backend. POST /users endpoint. Valida, salva 
no DB, retorna 201. Tests pytest 80% coverage. Response: 
Python code only."
```
Score: 9/10 | Tokens: ~65 | Δtokens: -57%

### Iteration 2 — After Medium Cuts (35 tokens)
```
"Python. POST /users: valida, DB, 201, pytest."
```
Score: 8/10 | Tokens: ~35 | Δtokens: -77%

### Iteration 3 — Optimal (18 tokens)
```
"Python API POST /users handler + tests."
```
Score: 7/10 | Tokens: ~18 | Δtokens: -88%

**Decision: Keep iteration 2 — best balance**

---

## Loop with Edge Case Discovery

### Iteration 0
```
"Create login endpoint."
```
Tokens: 5 | Score: 5/10

### Problem
Falta información para edge cases.

### Iteration 1
```
"Login endpoint. Input: email, password. Output: JWT.
Error: 401 invalid credentials."
```
Tokens: 20 | Score: 7/10

### Problem detected
No maneja rate limiting.

### Iteration 2
```
"Login endpoint. Input: {email, password}. 
Output: {token}. Errors: 401, 429.
Constraints: rate limit 5/min."
```
Tokens: 32 | Score: 9/10

**Result: +80% effectiveness for +60% tokens**

---

## Template for Loop Tracking

```markdown
## Iteration #[N]

### Before
```
[prompt]
```
Tokens: ~X | Scores: C:X, Co:X, R:X

### Changes
- [change 1]
- [change 2]

### After
```
[prompt]
```
Tokens: ~Y | Scores: C:Y, Co:Y, R:Y

### Delta
| Metric | Before | After | Δ |
|--------|--------|-------|---|
| Tokens | X | Y | Z% |
| Correctitud | X | Y | ±Z |
...

### Verdict
✅ Keep | ❌ Revert | 🔄 More work needed
```