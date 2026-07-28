# Python Attack Profile

## When to Load
`.py`, `.pyw` files with logic (not pure data/config).

## Language-Specific Vectors

### Injection
- `eval()` / `exec()` / `compile()` — dynamic code from user input?
- `os.system()` / `subprocess.Popen(shell=True)` — shell injection?
- `pickle.loads()` — deserialization RCE?
- `yaml.load()` — `yaml.Loader` vs safe `SafeLoader`?
- `__import__()` / `importlib` — dynamic module loading?
- `format()` / f-string — `{obj.__class__}` attribute access leak?
- `sqlite3` / ORM — raw SQL concatenation vs parameterized?

### Path & File
- `open()` with user path — `../` traversal?
- `shutil.copyfile()` — destination path traversal?
- `tempfile.mktemp()` — TOCTOU race vs `NamedTemporaryFile`?
- `os.walk()` — follows symlinks?
- `pathlib.Path.read_text()` — path from user input?

### Input Validation
- `int()` on user input — `int("1e999")` overflows?
- `float()` — precision loss on large/small values?
- `datetime.strptime()` — format string injection?
- `re.match()` / `re.search()` — ReDoS via crafted input?
- `json.loads()` — billion laughs attack via recursive objects?

### Concurrency
- `threading` — shared mutable state without Lock/RLock?
- `asyncio.gather()` — exception in one task affects others?
- `asyncio.wait()` — timeout not handled?
- `multiprocessing` — shared memory corruption?
- `queue.Queue` — blocking forever with no timeout?
- SQLite WAL mode — concurrent write race?

### Error & Resource
- Bare `except:` — catches `SystemExit`, `KeyboardInterrupt`?
- `finally` without cleanup — file descriptors leak?
- Context manager not used — file/connection not closed on exception?
- `yield` in `__del__` — `GeneratorExit` ignored?
- ResourceWarning — unclosed socket/file across scope?

### Security Boundary
- Hardcoded secret/API key in source?
- `assert` used for validation (disabled with `-O`)?
- Permission check only at entry — TOCTOU after auth?
- Timing side-channel on comparison (`==` vs `hmac.compare_digest`)?
- `ssl._create_unverified_context()` — skipped cert verification?
