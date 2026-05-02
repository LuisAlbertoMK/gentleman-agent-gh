---
name: go-testing
description: > Go testing patterns for Gentleman.Dots, Bubbletea TUI.
  Trigger: Go tests, teatest, test coverage.
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.0"
---

## PATTERNS
### Table-Driven
```go
func TestX(t *testing.T) {
    tests := []struct{n string; i string; e string; we bool}{
        {"ok","hello","HELLO",false},{"fail","","",true},
    }
    for _,tt:=range tests{t.Run(tt.n,func(t*testing.T){
        r,e:=F(tt.i)
        if(e!=nil)!=tt.we{t.Errorf("err=%v,we=%v",e,tt.we);return}
        if r!=tt.e{t.Errorf("got=%q,want=%q",r,tt.e)}
    })}}
```
### Bubbletea Model
```go
func TestM(t*testing.T){m:=NewModel();n,_:=m.Update(tea.KeyMsg{Type:tea.KeyEnter});m=n.(Model)
if m.S!=ScreenMainMenu{t.Errorf("got=%v,want=ScreenMainMenu",m.S)}}
```
### Teatest
```go
func TestFlow(t*testing.T){
    tm:=teatest.NewTestModel(t,NewModel())
    tm.Send(tea.KeyMsg{Type:tea.KeyEnter})
    tm.WaitFinished(t,teatest.WithDuration(time.Second))
    f:=tm.FinalModel(t).(Model)
    if f.Screen!=Exp{t.Errorf("got=%v,want=%v",f.Screen,Exp)}}
```
### Golden
```go
func TestG(t*testing.T){
    m:=NewModel();m.S=ScreenOS;m.W=80;m.H=24
    o:=m.View()
    g:=filepath.Join("testdata",t.Name()+".golden")
    if*update{os.WriteFile(g,[]byte(o),0644)}
    if o!=string(os.ReadFile(g)){t.Error("mismatch")}
}
```

## DECISION
```
Fn? → Table-driven
Eff? → Mock deps
Err? → test success+error

TUI? → State→Model.Update / Flow→teatest.NewTestModel / Visual→Golden / Keys→tea.KeyMsg

Exec? → Mock→intfc / Real→--short / Files→t.TempDir()
```

## COMMANDS
```bash
go test ./...     go test -v ./...    go test -run TestX
go test -cover   go test -update    go test -short
```