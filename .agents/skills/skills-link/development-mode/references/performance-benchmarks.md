# Performance Benchmarks

## Read Methods Comparison
```
File: 100MB log file
Method              Time    Memory
Get-Content         ~45s    450MB
StreamReader        ~8s     12MB
File.ReadAllBytes   ~3s     100MB
Memory-mapped       ~1.5s   2MB
```

## When to Use Dev Mode
| Scenario | Benefit |
|----------|---------|
| >50MB file reads | 5-10x faster |
| Multiple concurrent tools | Priority boost |
| Large git operations | Faster blame/diff |
| Heavy regex scans | CPU priority helps |
