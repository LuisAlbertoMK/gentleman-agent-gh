# code-generation — Reference Materials

> **Externalized from** .agents/skills/code-generation/SKILL.md to keep the skill under the 3KB
> token budget (ADR-007). Contains worked examples, testing patterns, edge cases,
> anti-patterns, and quick-reference cards.
> **Consumable by**: $Skill sub-agent when producing output.
## Anti-Patterns
Generate without reading existing code · Add unnecessary deps · Skip edge cases · Ignore codebase conventions · Silently propagate anti-patterns

## Examples

### Example 1: New React Component (TypeScript)
**Context**: Creating `UserCard.tsx` in `src/components/user/`
```tsx
import { User } from '@/types/user';
import { formatDate } from '@/utils/date';

interface UserCardProps {
  user: User;
  onEdit?: (id: string) => void;
}

export function UserCard({ user, onEdit }: UserCardProps) {
  if (!user) return null;
  
  return (
    <article className="user-card">
      <header>
        <h3>{user.name}</h3>
        <time dateTime={user.createdAt}>{formatDate(user.createdAt)}</time>
      </header>
      {onEdit && (
        <button onClick={() => onEdit(user.id)} aria-label={`Edit ${user.name}`}>
          Edit
        </button>
      )}
    </article>
  );
}
```
**Pattern source**: `src/components/user/UserList.tsx`, `src/components/common/Card.tsx`

---

### Example 2: Async Service Function (Go)
**Context**: Creating `GetUserByID` in `internal/user/service.go`
```go
func (s *UserService) GetUserByID(ctx context.Context, id string) (*User, error) {
    if id == "" {
        return nil, ErrInvalidID
    }
    
    user, err := s.repo.GetByID(ctx, id)
    if err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, ErrUserNotFound
        }
        return nil, fmt.Errorf("get user: %w", err)
    }
    return user, nil
}
```
**Pattern source**: `internal/user/repository.go`, `internal/common/errors.go`

---

### Example 3: CLI Command Scaffold (Python/Typer)
**Context**: Creating `scripts/deploy.py`
```python
import typer
from pathlib import Path
from deploy import Deployer, DeployConfig

app = typer.Typer(help="Deploy application to target environment")

@app.command()
def main(
    env: str = typer.Argument(..., help="Target environment (staging|prod)"),
    config: Path = typer.Option(Path("deploy.yaml"), "--config", "-c", help="Deploy config file"),
    dry_run: bool = typer.Option(False, "--dry-run", help="Simulate without changes"),
):
    """Deploy the application."""
    if env not in ("staging", "prod"):
        raise typer.BadParameter("env must be 'staging' or 'prod'")
    
    cfg = DeployConfig.from_file(config)
    deployer = Deployer(cfg, dry_run=dry_run)
    deployer.run(env)

if __name__ == "__main__":
    app()
```
**Pattern source**: `scripts/migrate.py`, `scripts/seed.py`

---

### Example 4: API Route Handler (FastAPI)
**Context**: Creating `src/api/routes/users.py`
```python
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.db.session import get_db
from src.schemas.user import UserCreate, UserResponse
from src.services.user import UserService, UserNotFoundError

router = APIRouter(prefix="/users", tags=["users"])

@router.post("", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(payload: UserCreate, db: AsyncSession = Depends(get_db)):
    service = UserService(db)
    try:
        user = await service.create(payload)
        return user
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(user_id: str, db: AsyncSession = Depends(get_db)):
    service = UserService(db)
    try:
        return await service.get_by_id(user_id)
    except UserNotFoundError:
        raise HTTPException(status_code=404, detail="User not found")
```
**Pattern source**: `src/api/routes/auth.py`, `src/services/user.py`

---

### Example 5: Utility Function with Tests (TypeScript)
**Context**: Creating `src/utils/validation.ts` + `src/utils/validation.test.ts`
```ts
// validation.ts
export function validateEmail(email: string): { valid: boolean; error?: string } {
    if (!email || typeof email !== 'string') {
        return { valid: false, error: 'Email is required' };
    }
    const pattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!pattern.test(email)) {
        return { valid: false, error: 'Invalid email format' };
    }
    if (email.length > 254) {
        return { valid: false, error: 'Email too long' };
    }
    return { valid: true };
}

// validation.test.ts
import { describe, it, expect } from 'vitest';
import { validateEmail } from './validation';

describe('validateEmail', () => {
    it('accepts valid emails', () => {
        expect(validateEmail('user@example.com')).toEqual({ valid: true });
        expect(validateEmail('test.email+tag@domain.org')).toEqual({ valid: true });
    });
    
    it('rejects invalid formats', () => {
        expect(validateEmail('invalid')).toEqual({ valid: false, error: 'Invalid email format' });
        expect(validateEmail('@nodomain')).toEqual({ valid: false, error: 'Invalid email format' });
    });
    
    it('handles edge cases', () => {
        expect(validateEmail('')).toEqual({ valid: false, error: 'Email is required' });
        expect(validateEmail('a'.repeat(255) + '@b.c')).toEqual({ valid: false, error: 'Email too long' });
        expect(validateEmail(null as any)).toEqual({ valid: false, error: 'Email is required' });
    });
});
```
**Pattern source**: `src/utils/string.ts`, `src/utils/string.test.ts`

---

## Testing Patterns

### Pattern 1: Unit Test with Mocks (Vitest/Jest)
```ts
// service.test.ts
import { vi, describe, it, expect, beforeEach } from 'vitest';
import { UserService } from './user.service';
import { UserRepository } from './user.repository';

describe('UserService', () => {
    let repo: UserRepository;
    let service: UserService;
    
    beforeEach(() => {
        repo = { findById: vi.fn(), create: vi.fn() } as any;
        service = new UserService(repo);
    });
    
    it('returns user when found', async () => {
        const user = { id: '1', name: 'Test' };
        vi.mocked(repo.findById).mockResolvedValue(user);
        
        const result = await service.getById('1');
        expect(result).toEqual(user);
    });
    
    it('throws when not found', async () => {
        vi.mocked(repo.findById).mockResolvedValue(null);
        await expect(service.getById('1')).rejects.toThrow('User not found');
    });
});
```

### Pattern 2: Integration Test with Test Database (Go)
```go
// service_integration_test.go
package user_test

import (
    "context"
    "testing"
    "github.com/stretchr/testify/require"
    "myapp/internal/user"
    "myapp/internal/db"
)

func TestUserService_Integration(t *testing.T) {
    pool := db.NewTestPool(t)
    defer pool.Close()
    
    repo := user.NewRepository(pool)
    svc := user.NewService(repo)
    
    t.Run("create and get user", func(t *testing.T) {
        created, err := svc.Create(context.Background(), user.CreateInput{Name: "Test"})
        require.NoError(t, err)
        
        got, err := svc.GetByID(context.Background(), created.ID)
        require.NoError(t, err)
        require.Equal(t, "Test", got.Name)
    })
}
```

### Pattern 3: E2E API Test (Playwright/Supertest)
```ts
// users.e2e.test.ts
import { test, expect } from '@playwright/test';

test.describe('Users API', () => {
    test('creates user and returns 201', async ({ request }) => {
        const response = await request.post('/api/users', {
            data: { name: 'John Doe', email: 'john@example.com' }
        });
        
        expect(response.status()).toBe(201);
        const body = await response.json();
        expect(body.id).toBeDefined();
        expect(body.name).toBe('John Doe');
    });
    
    test('returns 404 for non-existent user', async ({ request }) => {
        const response = await request.get('/api/users/nonexistent');
        expect(response.status()).toBe(404);
    });
});
```

---

## Edge Cases

### Edge Case 1: Null/Undefined Input Handling
Always validate inputs at function boundaries. Return explicit error types, not null.
```ts
// ❌ Bad: returns null silently
function process(user: User | null) { return user?.name; }

// ✅ Good: explicit validation
function process(user: User | null): Result<string> {
    if (!user) return err(new ValidationError('User required'));
    return ok(user.name);
}
```

### Edge Case 2: Empty Collections and Boundary Values
Handle empty arrays, zero, empty strings, and max limits explicitly.
```ts
function paginate<T>(items: T[], page: number, size: number): Paginated<T> {
    if (size <= 0) throw new Error('Page size must be positive');
    if (page < 1) throw new Error('Page must be >= 1');
    if (items.length === 0) return { items: [], total: 0, page, size };
    // ... pagination logic
}
```

### Edge Case 3: Resource Failures (Network, DB, Filesystem)
Wrap external calls with timeouts, retries, and circuit breakers.
```ts
async function fetchWithRetry<T>(url: string, retries = 3): Promise<T> {
    for (let i = 0; i < retries; i++) {
        try {
            return await fetchWithTimeout(url, 5000);
        } catch (e) {
            if (i === retries - 1) throw e;
            await sleep(1000 * (i + 1));
        }
    }
    throw new Error('Unreachable');
}
```

### Edge Case 4: Concurrency and Race Conditions
Use optimistic locking, idempotency keys, or distributed locks for mutable operations.
```ts
async function transfer(from: string, to: string, amount: number, idempotencyKey: string) {
    const lock = await acquireLock(`transfer:${idempotencyKey}`, 30_000);
    try {
        // Check idempotency
        const existing = await db.idempotencyKeys.find(idempotencyKey);
        if (existing) return existing.result;
        
        const result = await doTransfer(from, to, amount);
        await db.idempotencyKeys.create({ key: idempotencyKey, result });
        return result;
    } finally {
        await lock.release();
    }
}
```

---

## Anti-Patterns (Detailed)

### Anti-Pattern 1: Silent Anti-Pattern Propagation
**Problem**: Copying bad patterns from neighboring code without questioning them.
```ts
// Neighbor does this (anti-pattern):
const data = await db.query(`SELECT * FROM users WHERE id = ${id}`); // SQL injection!

// Generated code propagates it:
const user = await db.query(`SELECT * FROM users WHERE email = ${email}`); // Also vulnerable!
```
**Fix**: Flag to user: "Neighboring code uses raw SQL interpolation (SQL injection risk). Suggesting parameterized queries instead." Then generate safe code.

### Anti-Pattern 2: Phantom Dependency Introduction
**Problem**: Adding new dependencies that aren't in the codebase's lockfile.
```ts
// Generated code adds: import { z } from 'zod'; // Not in package.json!
function validate(data: unknown) { return z.object({...}).parse(data); }
```
**Fix**: Check `package.json` / `go.mod` / `Cargo.toml` first. Only use existing deps. If new dep needed: STOP, report [name]+[why]+[alternative using existing deps].

## Externalized Sections (ADR-007 compression)
## FILE CREATION
(1) Read parent dir to confirm structure. (2) Write file. (3) Verify syntax.


## DISAMBIGUATION
If request matches quick-executor scope (single existing file, clear before/after, <20 lines) → defer to quick-executor.


## SEVERITY
| P0 | Generated code breaks build | P1 | Convention mismatch | P2 | Missing edge case | P3 | Style nits |


