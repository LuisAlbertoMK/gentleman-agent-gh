# CI Workflow Example

```yaml
name: ci
on: [push, pull_request]
jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with: { go-version: 'stable' }
      - run: go vet ./...
      - run: go test ./... -race -coverprofile=coverage.out
      - run: go tool cover -func=coverage.out | grep total
  sdd-spec-coverage:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: |
          # Check each spec has corresponding tests
          $specs = Get-ChildItem -Recurse "specs/*.spec.md"
          $tests = Get-ChildItem -Recurse "*_test.go"
          # Validate coverage
```

## Auto-detect Runners
| File | Runner |
|------|--------|
| go.mod | `go test ./...` |
| package.json | `npm test` |
| *.csproj | `dotnet test` |
| Cargo.toml | `cargo test` |
| Gemfile | `bundle exec rspec` |
