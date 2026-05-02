---
name: go-testing
description: >
  Go testing patterns for Gentleman.Dots, including Bubbletea TUI testing.
  Trigger: Writing Go tests, using teatest, adding test coverage.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When
- Go unit tests, Bubbletea TUI, table-driven tests, integration, golden file testing

## Patterns

### 1: Table-Driven Tests
```go
func TestSomething(t *testing.T) {
    tests := []struct {
        name string; input string; expected string; wantErr bool
    }{
        {"valid input", "hello", "HELLO", false},
        {"empty input", "", "", true},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result, err := ProcessInput(tt.input)
            if (err != nil) != tt.wantErr { t.Errorf("error = %v, wantErr %v", err, tt.wantErr); return }
            if result != tt.expected { t.Errorf("got %q, want %q", result, tt.expected) }
        })
    }
}
```

### 2: Bubbletea Model Testing
```go
func TestModelUpdate(t *testing.T) {
    m := NewModel()
    newModel, _ := m.Update(tea.KeyMsg{Type: tea.KeyEnter})
    m = newModel.(Model)
    if m.Screen != ScreenMainMenu { t.Errorf("expected ScreenMainMenu, got %v", m.Screen) }
}
```

### 3: Teatest Integration
```go
func TestInteractiveFlow(t *testing.T) {
    tm := teatest.NewTestModel(t, NewModel())
    tm.Send(tea.KeyMsg{Type: tea.KeyEnter})
    tm.WaitFinished(t, teatest.WithDuration(time.Second))
    finalModel := tm.FinalModel(t).(Model)
    if finalModel.Screen != ExpectedScreen { t.Errorf("wrong screen: got %v", finalModel.Screen) }
}
```

### 4: Golden File Testing
```go
func TestViewGolden(t *testing.T) {
    m := NewModel(); m.Screen = ScreenOSSelect; m.Width = 80; m.Height = 24
    output := m.View()
    golden := filepath.Join("testdata", t.Name()+".golden")
    if *update { os.WriteFile(golden, []byte(output), 0644) }
    expected, _ := os.ReadFile(golden)
    if output != string(expected) { t.Errorf("output doesn't match golden") }
}
```

## Decision Tree
```
Pure function? → Table-driven test
Has side effects? → Mock dependencies
Returns error? → Test both success + error

Testing TUI?
  State change → Test Model.Update() directly
  Full flow → teatest.NewTestModel()
  Visual output → Golden file testing
  Key handling → Send tea.KeyMsg

System/exec?
  Mock → interface + mock
  Real commands → integration test with --short skip
  File ops → t.TempDir()
```

## Examples
### Cursor Navigation
```go
func TestCursorNavigation(t *testing.T) {
    tests := []struct {
        name string; startPos int; key string; endPos int; numOptions int
    }{
        {"down from 0", 0, "j", 1, 5}, {"up from 1", 1, "k", 0, 5},
        {"down at bottom", 4, "j", 4, 5}, {"up at top", 0, "k", 0, 5},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            m := NewModel(); m.Cursor = tt.startPos
            newModel, _ := m.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune(tt.key)})
            m = newModel.(Model)
            if m.Cursor != tt.endPos { t.Errorf("cursor = %d, want %d", m.Cursor, tt.endPos) }
        })
    }
}
```

### Screen Transitions
```go
func TestScreenTransitions(t *testing.T) {
    tests := []struct {
        name string; startScreen Screen; action tea.Msg; expectScreen Screen
    }{
        {"welcome→main", ScreenWelcome, tea.KeyMsg{Type: tea.KeyEnter}, ScreenMainMenu},
        {"escape from OS", ScreenOSSelect, tea.KeyMsg{Type: tea.KeyEsc}, ScreenMainMenu},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            m := NewModel(); m.Screen = tt.startScreen
            newModel, _ := m.Update(tt.action); m = newModel.(Model)
            if m.Screen != tt.expectScreen { t.Errorf("screen = %v, want %v", m.Screen, tt.expectScreen) }
        })
    }
}
```

## File Organization
```
internal/tui/
├── model.go / model_test.go
├── update.go / update_test.go
├── view.go / view_test.go
├── teatest_test.go
├── testdata/*.golden
└── trainer/*.go / *_test.go
```

## Commands
```bash
go test ./...              go test -v ./internal/tui/...     go test -run TestNavigation
go test -cover ./...       go test -update ./...              go test -short ./...
```
