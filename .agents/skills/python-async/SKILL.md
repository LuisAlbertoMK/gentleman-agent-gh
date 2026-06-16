---
name: python-async
description: "Python async/await patterns — gather vs create_task vs TaskGroup, deadlock prevention, and common asyncio pitfalls"
triggers: "Python async, asyncio"
license: Apache-2.0
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "1.2"
  changelog: "1.1->1.2 (sprint 5: 78->56 lines
---

Trigger: Python async, asyncio, coroutines, event loop.
## WhenDebugging async deadlocks Â· Concurrent tasks Â· Fire-and-forget Â· Event loop management
## gather vs create_task vs TaskGroup| **gather** | **create_task** | **TaskGroup (3.11+)** ||-----------|-----------------|---------------------|| Ordered results | Unordered | Ordered (by add) || Auto-exception propagate | Manual handle | First fail cancels rest || Cancels all on one fail | Independent | ExceptionGroups || Use: known coro set | Use: dynamic/fire-forget | Use: related tasks |
## Deadlock prevention- NEVER block event loop with sync calls (`time.sleep` â†’ `asyncio.sleep`)- `asyncio.timeout()` or `wait_for()` to avoid hangs- `gather(return_exceptions=True)` for graceful error handling- Maintain strong refs: `background_tasks.add(task); task.add_done_callback(background_tasks.discard)`- Detect cycles: `python -m asyncio pstree <pid>`
## Common pitfalls- Forgetting `await` â†’ returns coroutine, not result- Mixing sync/async libs â†’ blocks event loop- GC-collected tasks â†’ cancelled silently â†’ keep strong refs- `asyncio.run()` called multiple times â†’ RuntimeError (single entry point)
## Components
### gather
```pythonresults = await asyncio.gather(    fetch("a"), fetch("b"), fetch("c"),    return_exceptions=True  # don't cancel all on first error)```
### create_task (fire-and-forget)
```pythonbackground_tasks = set()async def background_work():    task = asyncio.create_task(some_coro())    background_tasks.add(task)    task.add_done_callback(background_tasks.discard)```
### TaskGroup (3.11+)
```pythonasync with asyncio.TaskGroup() as tg:    t1 = tg.create_task(fetch("a"))    t2 = tg.create_task(fetch("b"))```
### Timeout
```pythonasync with asyncio.timeout(5.0):    result = await slow_operation()```
## Commands
```bashpython -m asyncio pstree <pid>         # detect await graph cyclespython -c "import asyncio; asyncio.run(main())"  # single entry```
