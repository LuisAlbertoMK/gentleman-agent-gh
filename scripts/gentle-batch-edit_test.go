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
	if err := os.WriteFile(p, []byte("a.b.c"), 0o644); err != nil {
		t.Fatal(err)
	}
	r := process(specLine{File: p, Replacements: []repl{{Old: ".", New: "_"}}}, true)
	if r.Err != nil {
		t.Fatalf("dry-run: unexpected error: %v", r.Err)
	}
	if r.Edits != 2 {
		t.Errorf("dry-run edits = %d, want 2", r.Edits)
	}
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
	if err := os.WriteFile(p, []byte("foo bar foo"), 0o644); err != nil {
		t.Fatal(err)
	}
	r := process(specLine{File: p, Replacements: []repl{{Old: "foo", New: "baz"}}}, false)
	if r.Err != nil {
		t.Fatalf("apply: unexpected error: %v", r.Err)
	}
	if r.Edits != 2 {
		t.Errorf("edits = %d, want 2", r.Edits)
	}
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
	if err := os.WriteFile(p, []byte("abc"), 0o644); err != nil {
		t.Fatal(err)
	}
	r := process(specLine{File: p, Replacements: []repl{{Old: "", New: "x"}, {Old: "zzz", New: "y"}}}, false)
	if r.Err != nil {
		t.Fatalf("unexpected error: %v", r.Err)
	}
	if r.Edits != 0 {
		t.Errorf("edits = %d, want 0", r.Edits)
	}
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
	if err := json.Unmarshal([]byte(in), &s); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}
	if s.File != "a/b" || len(s.Replacements) != 1 ||
		s.Replacements[0].Old != "x" || s.Replacements[0].New != "y" {
		t.Errorf("unexpected specLine: %+v", s)
	}
}

func mustReadDir(t *testing.T, dir string) []os.DirEntry {
	t.Helper()
	entries, err := os.ReadDir(dir)
	if err != nil {
		t.Fatal(err)
	}
	return entries
}

// TestApplyReplacements exercises the PURE core via idiomatic Go table-driven
// tests — deterministic, no filesystem, covers every branch of the replace loop.
func TestApplyReplacements(t *testing.T) {
	tests := []struct {
		name      string
		src       string
		rs        []repl
		dryRun    bool
		wantEdits int
		wantOut   string
	}{
		{"no match", "abc", []repl{{Old: "x", New: "y"}}, false, 0, "abc"},
		{"skip empty old", "abc", []repl{{Old: "", New: "y"}}, false, 0, "abc"},
		{"zero count skipped", "abc", []repl{{Old: "z", New: "y"}}, false, 0, "abc"},
		{"replace all (2 dots)", "a.b.c", []repl{{Old: ".", New: "_"}}, false, 2, "a_b_c"},
		{"dry-run counts, no mutate", "a.b.c", []repl{{Old: ".", New: "_"}}, true, 2, "a.b.c"},
		{"multiple cumulative (2 dots + 1 b = 3)", "a.b.c", []repl{{Old: ".", New: "_"}, {Old: "b", New: "X"}}, false, 3, "a_X_c"},
		{"dry multi counts on ORIGINAL src", "a.b.c", []repl{{Old: ".", New: "_"}, {Old: "b", New: "X"}}, true, 3, "a.b.c"},
		{"empty src", "", []repl{{Old: "x", New: "y"}}, false, 0, ""},
		{"nil repls", "abc", nil, false, 0, "abc"},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			edits, out := applyReplacements(tc.src, tc.rs, tc.dryRun)
			if edits != tc.wantEdits {
				t.Errorf("applyReplacements edits = %d, want %d", edits, tc.wantEdits)
			}
			if out != tc.wantOut {
				t.Errorf("applyReplacements out = %q, want %q", out, tc.wantOut)
			}
		})
	}
}
