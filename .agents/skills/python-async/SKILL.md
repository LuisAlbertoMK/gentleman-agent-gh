---
name: python-async
description: "Python async/await patterns -- gather vs create_task vs TaskGroup, deadlock prevention, and common asyncio pitfalls"
triggers: "Python async, asyncio"
license: Apache-2.0
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "1.3"
  changelog: "1.2->1.3 (Karpathy compress: 2587->1600B)"
---

## gather vs create_task vs TaskGroup
| gather | create_task | TaskGroup (3.11+) |
|--------|-------------|-------------------|
| Ordered results | Unordered | Ordered (by add) |
| Auto-exception propagate | Manual handle | First fail cancels rest |
| Cancels all on one fail | Independent | ExceptionGroups |
| Use: known coro set | Use: dynamic/fire-forget | Use: related tasks |

## Deadlock prevention
- NEVER block event loop: `time.sleep` -> `asyncio.sleep`
- `asyncio.timeout()` / `wait_for()` to avoid hangs
- `gather(return_exceptions=True)` for fault-tolerant fan-out
- Strong refs: `background_tasks.add(task); task.add_done_callback(background_tasks.discard)`
- Detect cycles: `python -m asyncio pstree <pid>`
- Always `async with` for resources (aiohttp, aiofiles)

## Common pitfalls
- Forgetting `await` -> returns coroutine, not result
- Mixing sync/async libs -> blocks event loop
- GC-collected tasks -> cancelled silently -> keep strong refs
- Multiple `asyncio.run()` calls -> RuntimeError (single entry point)

## Code patterns
```python
# gather -- fault-tolerant fan-out
results = await asyncio.gather(fetch("a"), fetch("b"), return_exceptions=True)

# create_task -- fire-and-forget with strong ref
background_tasks.add(task); task.add_done_callback(background_tasks.discard)

# TaskGroup (3.11+) -- auto-cancels siblings on failure
async with asyncio.TaskGroup() as tg:
    t1 = tg.create_task(fetch("a"))

# timeout
async with asyncio.timeout(5.0):
    result = await slow_operation()
```

## Commands
```bash
python -m asyncio pstree <pid>         # await graph cycles
python -c "import asyncio; asyncio.run(main())"
```
