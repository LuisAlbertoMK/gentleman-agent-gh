# Async Antipatterns

## Pitfall: Sync call in async context
```python
# BAD — blocks event loop
async def fetch_data():
    time.sleep(2)  # blocks ALL tasks
    return requests.get("http://api.example.com")

# GOOD — cooperative
async def fetch_data():
    await asyncio.sleep(2)
    async with aiohttp.ClientSession() as session:
        async with session.get("http://api.example.com") as resp:
            return await resp.text()
```

## Pitfall: Forgotten await
```python
# BAD — returns coroutine, not result
result = fetch_data()  # <coroutine object at 0x...>

# GOOD
result = await fetch_data()
```

## Pitfall: Task garbage collection
```python
# BAD — task cancelled on next GC
async def fire_and_forget():
    asyncio.create_task(background_work())

# GOOD — keep strong reference
background_tasks = set()
async def fire_and_forget():
    task = asyncio.create_task(background_work())
    background_tasks.add(task)
    task.add_done_callback(background_tasks.discard)
```
