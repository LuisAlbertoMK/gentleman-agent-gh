---
name: go-testing
description: "Go testing patterns — table-driven tests, Bubbletea TUI testing with teatest, golden files, and mock strategies"
triggers: "Go tests, Bubbletea TUI"
license: Apache-2.0
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "1.2"
---

Trigger: Go tests, teatest, test coverage.

## Table-Driven
```go
func TestX(t *testing.T) {
    tests := []struct{n string; i string; e string; we bool}{
        {"ok","hello","HELLO",false},{"fail","","",true},
    }
    for _,tt:=range tests{t.Run(tt.n,func(t*testing.T){
        r,e:=F(tt.i)
        if(e!=nil)!=tt.we{t.Errorf("err=%v,we=%v",e,tt.we)}
        if r!=tt.e{t.Errorf("got=%q,want=%q",r,tt.e)}
    })}
}
```

## Bubbletea
```go
func TestM(t*testing.T){m:=NewModel();n,_:=m.Update(tea.KeyMsg{Type:tea.KeyEnter})
if m.S!=ScreenMainMenu{t.Errorf("got=%v,want=ScreenMainMenu",m.S)}}

func TestFlow(t*testing.T){
    tm:=teatest.NewTestModel(t,NewModel())
    tm.Send(tea.KeyMsg{Type:tea.KeyEnter})
    tm.WaitFinished(t,teatest.WithDuration(time.Second))
    f:=tm.FinalModel(t).(Model)
    if f.Screen!=Exp{t.Errorf("got=%v,want=%v",f.Screen,Exp)}
}

func TestGolden(t*testing.T){
    m:=NewModel();m.S=ScreenOS;m.W=80;m.H=24
    o:=m.View()
    g:=filepath.Join("testdata",t.Name()+".golden")
    if*update{os.WriteFile(g,[]byte(o),0644)}
    if o!=string(os.ReadFile(g)){t.Error("mismatch")}
}
```

## Decision Guide
| Question | Strategy |
|----------|----------|
| DecisionFn? | → Table-driven |
| Effect? | → Mock interface |
| Error? | → success + error return |
| TUI State? | → Model.Update |
| TUI Flow? | → teatest test model |
| TUI Visual? | → Golden file |
| TUI Keys? | → tea.KeyMsg |
| Exec Mock? | → Interface mock |
| Exec Real? | → go test -short |
| Exec Files? | → t.TempDir() |

## Commands
```bash
go test ./...        go test -v ./...      go test -run TestX
go test -cover       go test -update       go test -short
```
