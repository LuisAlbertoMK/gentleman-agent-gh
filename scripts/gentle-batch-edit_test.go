package main

import (
    "encoding/json"
    "os"
    "path/filepath"
    "strings"
    "testing"
)

// TestProcessDryRunCountsEditsWithoutWriting checks the -n path: counts
// occurrences but leaves the file untouched.
func TestProcessDryRunCountsEditsWithoutWriting(t *testing.T) {
    dir := t.TempDir()
    p := filepath.Join(dir, "in.txt")
    if err := os.WriteFile(p, []byte("a.b.c"), 0o644); err != nil { t.Fatal(err) }
    r := process(specLine{File: p, Replacements: []repl{{Old: ".", New: "_"}}}, true)
    if r.Err != nil { t.Fatalf("dry-run: unexpected error: %v", r.Err) }
    if r.Edits != 2 { t.Errorf("dry-run edits = %d, want 2", r.Edits) }
    if got, _ := os.ReadFile(p); string(got) != "a.b.c" {
        t.Errorf("dry-run must not modify file: got %q", got)
    }
}

// TestProcessAppliesReplacementsAndRenames covers the write path: it replaces
// all occurrences, reports the count, and verifies atomic rename + no leftover
// temp (.gbe-*) files in the same directory.
func TestProcessAppliesReplacementsAndRenames(t *testing.T) {
    dir := t.TempDir()
    p := filepath.Join(dir, "in.txt")
    if err := os.WriteFile(p, []byte("foo bar foo"), 0o644); err != nil { t.Fatal(err) }
    r := process(specLine{File: p, Replacements: []repl{{Old: "foo", New: "baz"}}}, false)
    if r.Err != nil { t.Fatalf("apply: unexpected error: %v", r.Err) }
    if r.Edits != 2 { t.Errorf("edits = %d, want 2", r.Edits) }
    if got, _ := os.ReadFile(p); string(got) != "baz bar baz" {
        t.Errorf("result = %q, want %q", got, "baz bar baz")
    }
    for _, f := range mustReadDir(t, dir) {
        if strings.HasPrefix(f.Name(), ".gbe-") {
            t.Errorf("leftover temp file: %s", f.Name())
        }
    }
}

// TestProcessSkipsEmptyOldAndZeroCount: empty Old is skipped and a non-matching
// Old produces zero edits / no write.
func TestProcessSkipsEmptyOldAndZeroCount(t *testing.T) {
    dir := t.TempDir()
    p := filepath.Join(dir, "in.txt")
    if err := os.WriteFile(p, []byte("abc"), 0o644); err != nil { t.Fatal(err) }
    r := process(specLine{File: p, Replacements: []repl{{Old: "", New: "x"}, {Old: "zzz", New: "y"}}}, false)
    if r.Err != nil { t.Fatalf("unexpected error: %v", r.Err) }
    if r.Edits != 0 { t.Errorf("edits = %d, want 0", r.Edits) }
    if got, _ := os.ReadFile(p); string(got) != "abc" {
        t.Errorf("file should be unchanged, got %q", got)
    }
}

// TestProcessMissingFileReturnsError: fail-closed on unreadable files.
func TestProcessMissingFileReturnsError(t *testing.T) {
    r := process(specLine{File: filepath.Join(t.TempDir(), "nope.txt"), Replacements: nil}, false)
    if r.Err == nil {
        t.Error("expected error for missing file, got nil")
    }
}

// TestSpecLineUnmarshal: the JSONL spec contract (file + replacements.old/new).
func TestSpecLineUnmarshal(t *testing.T) {
    var s specLine
    in := `{"file":"a/b","replacements":[{"old":"x","new":"y"}]}`
    if err := json.Unmarshal([]byte(in), &s); err != nil { t.Fatalf("unmarshal: %v", err) }
    if s.File != "a/b" || len(s.Replacements) != 1 ||
        s.Replacements[0].Old != "x" || s.Replacements[0].New != "y" {
        t.Errorf("unexpected specLine: %+v", s)
    }
}

func mustReadDir(t *testing.T, dir string) []os.DirEntry {
    t.Helper()
    entries, err := os.ReadDir(dir)
    if err != nil { t.Fatal(err) }
    return entries
}
