package config

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestFilesystemPathAcceptsAbsolutePath(t *testing.T) {
	got, err := filesystemPath("/Users/example/Vault")
	if err != nil {
		t.Fatal(err)
	}
	if got != "/Users/example/Vault" {
		t.Fatalf("path = %q", got)
	}
}

func TestFilesystemPathExpandsHome(t *testing.T) {
	got, err := filesystemPath("~/Vault")
	if err != nil {
		t.Fatal(err)
	}
	home, err := os.UserHomeDir()
	if err != nil {
		t.Fatal(err)
	}
	want := filepath.Join(home, "Vault")
	if got != want {
		t.Fatalf("path = %q, want %q", got, want)
	}
}

func TestFilesystemPathRejectsRelativePath(t *testing.T) {
	_, err := filesystemPath("backend/testdata/vault")
	if err == nil || !strings.Contains(err.Error(), "must start with / or ~/") {
		t.Fatalf("error = %v", err)
	}
}

func TestFilesystemPathIsRequired(t *testing.T) {
	_, err := filesystemPath("")
	if err == nil || !strings.Contains(err.Error(), "is required") {
		t.Fatalf("error = %v", err)
	}
}
