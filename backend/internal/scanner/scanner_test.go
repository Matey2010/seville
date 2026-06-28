package scanner

import (
	"path/filepath"
	"testing"

	knowledgev1 "github.com/Matey2010/seville/proto/gen/go/seville/knowledge/v1"
)

func TestScanFixtureVault(t *testing.T) {
	snapshot, err := Scan(filepath.Join("..", "..", "testdata", "vault"))
	if err != nil {
		t.Fatal(err)
	}
	if len(snapshot.Notes) != 2 {
		t.Fatalf("notes = %d, want 2", len(snapshot.Notes))
	}
	if len(snapshot.Links) != 2 {
		t.Fatalf("links = %d, want 2", len(snapshot.Links))
	}
	if snapshot.Notes[0].Title != "Home" {
		t.Fatalf("first title = %q, want Home", snapshot.Notes[0].Title)
	}
	if snapshot.Links[0].Kind != knowledgev1.LinkKind_LINK_KIND_WIKI {
		t.Fatalf("first link kind = %v, want wiki", snapshot.Links[0].Kind)
	}
	if snapshot.Links[0].ResolvedTargetId == nil {
		t.Fatal("wiki link was not resolved")
	}
	if snapshot.Revision == "" {
		t.Fatal("revision is empty")
	}
}

func TestRevisionIsStable(t *testing.T) {
	root := filepath.Join("..", "..", "testdata", "vault")
	first, err := Scan(root)
	if err != nil {
		t.Fatal(err)
	}
	second, err := Scan(root)
	if err != nil {
		t.Fatal(err)
	}
	if first.Revision != second.Revision {
		t.Fatalf("revision changed: %s != %s", first.Revision, second.Revision)
	}
}

func TestFrontmatterBlockListTags(t *testing.T) {
	frontmatter, _, warning := parseFrontmatter("" +
		"---\n" +
		"title: Tagged note\n" +
		"tags:\n" +
		"  - node\n" +
		"  - science\n" +
		"aliases:\n" +
		"  - Example\n" +
		"---\n" +
		"Body\n")
	if warning != "" {
		t.Fatal(warning)
	}
	tags := collectTags(frontmatter["tags"], "")
	if len(tags) != 2 || tags[0] != "node" || tags[1] != "science" {
		t.Fatalf("tags = %v, want [node science]", tags)
	}
}
