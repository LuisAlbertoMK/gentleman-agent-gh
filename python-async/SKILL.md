---
name: python-async
description: > Python asyncio patterns: async/await, concurrency, deadlock prevention.
  Trigger: Python async, asyncio, coroutines, event loop.
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.1"
---

## When
Debugging async deadlocks · Concurrent task execution · Fire-and-forget patterns · Event loop management

## Critical Patterns

### gather vs create_task
| **gather** | **create_task** | **TaskGroup (3.11+)** |
|-----------|-----------------|---------------------|
| Ordered results | Unordered tasks | Ordered (by add order) |
| Auto-exception propagation | Manual exception handling | Structured: first fail cancels rest |
| Cancels all on one fail | Independent lifecycle | ExceptionGroups for multiple errors |
| Use: known set of coros | Use: dynamic/fire-and-forget | Use: group of related tasks |

### Deadlock prevention
- NEVER block the event loop with sync calls (`time.sleep` → `asyncio.sleep`)
- Use `asyncio.timeout()` or `asyncio.wait_for()` to avoid hangs
- `gather(return_exceptions=True)` for graceful error handling
- Maintain strong refs to tasks: `background_tasks.add(task); task.add_done_callback(background_tasks.discard)`
- Detect cycles: `python -m asyncio pstree <pid>`

### Common pitfalls
- Forgetting `await` → returns coroutine, not result
- Mixing sync/async libraries → blocks event loop
- Garbage-collected tasks → cancelled silently → keep strong references
- `asyncio.run()` called multiple times → RuntimeError (use single entry point)

## Components

### gather
```python
results = await asyncio.gather(
    fetch("a"), fetch("b"), fetch("c"),
    return_exceptions=True  # don't cancel all on first error
)
```

### create_task (fire-and-forget)
```python
background_tasks = set()

async def background_work():
    task = asyncio.create_task(some_coro())
    background_tasks.add(task)
    task.add_done_callback(background_tasks.discard)
```

### TaskGroup (3.11+)
```python
try:
    async with asyncio.TaskGroup() as tg:
        t1 = tg.create_task(fetch("a"))
        t2 = tg.create_task(fetch("b"))
except* asyncio.TimeoutError as eg:
    print(f"Tasks timed out: {eg.exceptions}")
```

### Timeout guard
```python
try:
    async with asyncio.timeout(5.0):
        result = await slow_operation()
except asyncio.TimeoutError:
    print("Timed out")
```

## Commands
```bash
python -m asyncio pstree <pid>    # detect await graph cycles
python -c "import asyncio; asyncio.run(main())"  # single entry point
```
