# SDD Init Examples

## Config Output
```yaml
# openspec/config.yaml
schema: spec-driven
context:
  tech: Go 1.22 + Chi router
  arch: Clean Architecture (handler→service→store)
  test: go test (standard)
  style: golangci-lint (go vet + staticcheck)
strict_tdd: true
```

## Init Summary
```
SDD INIT | Project: my-api | Stack: Go 1.22 + Chi
Strict TDD: enabled
Caps: go test, unit+integration, -cover, golangci-lint
Saved: engram-obs-55, openspec/config.yaml
```

## Detection Priority
1. `package.json` → Node/TS
2. `go.mod` → Go
3. `pyproject.toml` → Python
4. `Cargo.toml` → Rust
5. `*.csproj` → .NET
