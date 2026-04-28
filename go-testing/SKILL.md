---
name: go-testing
description: >
  Go testing: table-driven, Bubbletea TUI, golden files.
  Triggers: "go test", "teatest", "test coverage".
---

## Patterns

### Table-Driven
```go
func TestX(t *testing.T) {
    tests := []struct {
        name, input, expected string
        wantErr bool
    }{
        {"ok", "hello", "HELLO", false},
        {"err", "", "", true},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := fn(tt.input)
            if (err != nil) != tt.wantErr {
                t.Errorf("err = %v, wantErr %v", err, tt.wantErr)
            }
            if got != tt.expected {
                t.Errorf("got %q, want %q", got, tt.expected)
            }
        })
    }
}
```

### Bubbletea Model
```go
func TestModelUpdate(t *testing.T) {
    m := NewModel()
    newM, _ := m.Update(tea.KeyMsg{Type: tea.KeyEnter})
    m = newM.(Model)
    if m.Screen != ScreenMainMenu {
        t.Errorf("got %v, want ScreenMainMenu", m.Screen)
    }
}
```

### Teatest
```go
func TestFlow(t *testing.T) {
    m := NewModel()
    tm := teatest.NewTestModel(t, m)
    tm.Send(tea.KeyMsg{Type: tea.KeyEnter})
    tm.WaitFinished(t, teatest.WithDuration(time.Second))
    final := tm.FinalModel(t).(Model)
    if final.Screen != Expected {
        t.Errorf("got %v", final.Screen)
    }
}
```

### Golden Files
```go
func TestGolden(t *testing.T) {
    out := model.View()
    golden := filepath.Join("testdata", "TestX.golden")
    if *update { os.WriteFile(golden, []byte(out), 0644) }
    expected, _ := os.ReadFile(golden)
    if out != string(expected) { t.Error("mismatch") }
}
```

## Decision Tree

```
Test function?
├── Pure → table-driven
├── Side effects → mock
└── Error → test ok + err

Test TUI?
├── State → test Model.Update()
├── Flow → teatest
└── Visual → golden files
```

## Commands

```bash
go test ./...           # all
go test -v ./...        # verbose
go test -cover ./...   # coverage
go test -update ./...   # update golden
go test -short ./...   # skip integration
```

* go-testing v2.0 — Karpathy Optimized *