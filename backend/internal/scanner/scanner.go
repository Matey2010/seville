package scanner

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"slices"
	"strings"
	"time"

	knowledgev1 "github.com/Matey2010/seville/proto/gen/go/seville/knowledge/v1"
	"google.golang.org/protobuf/types/known/timestamppb"
)

var (
	headingPattern   = regexp.MustCompile(`(?m)^#\s+(.+?)\s*$`)
	inlineTagPattern = regexp.MustCompile(`(?:^|[\s(])#([\pL\pN_/-]+)`)
	wikiPattern      = regexp.MustCompile(`(!?)\[\[([^\]]+)\]\]`)
	markdownPattern  = regexp.MustCompile(`!?\[([^\]]*)\]\(([^)]+)\)`)
)

type candidate struct {
	note  *knowledgev1.Note
	links []*knowledgev1.Link
}

func Scan(root string) (*knowledgev1.KnowledgeSnapshot, error) {
	info, err := os.Stat(root)
	if err != nil {
		return nil, fmt.Errorf("open vault: %w", err)
	}
	if !info.IsDir() {
		return nil, fmt.Errorf("vault path is not a directory")
	}

	var candidates []candidate
	var warnings []*knowledgev1.ScanWarning
	err = filepath.WalkDir(root, func(path string, entry os.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		if entry.IsDir() {
			if path != root && (strings.HasPrefix(entry.Name(), ".") || entry.Name() == ".obsidian") {
				return filepath.SkipDir
			}
			return nil
		}
		if strings.ToLower(filepath.Ext(entry.Name())) != ".md" {
			return nil
		}

		relative, err := filepath.Rel(root, path)
		if err != nil {
			return err
		}
		relative = filepath.ToSlash(relative)
		parsed, warning, err := parseFile(path, relative)
		if err != nil {
			warnings = append(warnings, &knowledgev1.ScanWarning{Path: relative, Message: err.Error()})
			return nil
		}
		if warning != "" {
			warnings = append(warnings, &knowledgev1.ScanWarning{Path: relative, Message: warning})
		}
		candidates = append(candidates, parsed)
		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("walk vault: %w", err)
	}

	slices.SortFunc(candidates, func(a, b candidate) int {
		return strings.Compare(a.note.Path, b.note.Path)
	})
	resolveLinks(candidates)

	snapshot := &knowledgev1.KnowledgeSnapshot{
		GeneratedAt: timestamppb.New(time.Now().UTC()),
		Warnings:    warnings,
	}
	for _, item := range candidates {
		snapshot.Notes = append(snapshot.Notes, item.note)
		snapshot.Links = append(snapshot.Links, item.links...)
	}
	snapshot.Revision = revision(snapshot)
	return snapshot, nil
}

func parseFile(path, relative string) (candidate, string, error) {
	content, err := os.ReadFile(path)
	if err != nil {
		return candidate{}, "", fmt.Errorf("read note: %w", err)
	}
	info, err := os.Stat(path)
	if err != nil {
		return candidate{}, "", fmt.Errorf("stat note: %w", err)
	}

	body := string(content)
	frontmatter, bodyWithoutFrontmatter, warning := parseFrontmatter(body)
	title := strings.TrimSpace(frontmatter["title"])
	if title == "" {
		if match := headingPattern.FindStringSubmatch(bodyWithoutFrontmatter); match != nil {
			title = strings.TrimSpace(match[1])
		}
	}
	if title == "" {
		title = strings.TrimSuffix(filepath.Base(relative), filepath.Ext(relative))
	}

	tags := collectTags(frontmatter["tags"], bodyWithoutFrontmatter)
	note := &knowledgev1.Note{
		Id:          noteID(relative),
		Path:        relative,
		Title:       title,
		Body:        body,
		Tags:        tags,
		Frontmatter: frontmatter,
		ModifiedAt:  timestamppb.New(info.ModTime().UTC()),
	}
	return candidate{note: note, links: extractLinks(note.Id, bodyWithoutFrontmatter)}, warning, nil
}

func parseFrontmatter(body string) (map[string]string, string, string) {
	values := make(map[string]string)
	if !strings.HasPrefix(body, "---\n") {
		return values, body, ""
	}
	end := strings.Index(body[4:], "\n---")
	if end < 0 {
		return values, body, "frontmatter starts but has no closing delimiter"
	}
	end += 4
	block := body[4:end]
	currentKey := ""
	for _, line := range strings.Split(block, "\n") {
		trimmedLine := strings.TrimSpace(line)
		if len(line) > len(strings.TrimLeft(line, " \t")) {
			if currentKey != "" && strings.HasPrefix(trimmedLine, "-") {
				item := strings.Trim(strings.TrimSpace(strings.TrimPrefix(trimmedLine, "-")), `"'`)
				if item != "" {
					if values[currentKey] != "" {
						values[currentKey] += ","
					}
					values[currentKey] += item
				}
			}
			continue
		}
		key, value, ok := strings.Cut(line, ":")
		if !ok || strings.TrimSpace(key) == "" {
			currentKey = ""
			continue
		}
		currentKey = strings.TrimSpace(key)
		values[currentKey] = strings.Trim(strings.TrimSpace(value), `"'`)
	}
	bodyStart := end + len("\n---")
	if bodyStart < len(body) && body[bodyStart] == '\n' {
		bodyStart++
	}
	return values, body[bodyStart:], ""
}

func collectTags(frontmatterTags, body string) []string {
	set := make(map[string]struct{})
	trimmed := strings.Trim(frontmatterTags, "[]")
	for _, tag := range strings.FieldsFunc(trimmed, func(r rune) bool {
		return r == ',' || r == ' '
	}) {
		tag = strings.Trim(strings.TrimSpace(tag), `"'#`)
		if tag != "" {
			set[tag] = struct{}{}
		}
	}
	for _, match := range inlineTagPattern.FindAllStringSubmatch(body, -1) {
		set[match[1]] = struct{}{}
	}
	tags := make([]string, 0, len(set))
	for tag := range set {
		tags = append(tags, tag)
	}
	slices.Sort(tags)
	return tags
}

func extractLinks(sourceID, body string) []*knowledgev1.Link {
	var links []*knowledgev1.Link
	for _, match := range wikiPattern.FindAllStringSubmatch(body, -1) {
		target, display := splitAlias(match[2])
		target, fragment := splitFragment(target)
		kind := knowledgev1.LinkKind_LINK_KIND_WIKI
		if match[1] == "!" {
			kind = knowledgev1.LinkKind_LINK_KIND_EMBED
		}
		link := &knowledgev1.Link{SourceNoteId: sourceID, TargetText: target, Kind: kind}
		if display != "" {
			link.DisplayText = &display
		}
		if fragment != "" {
			link.Fragment = &fragment
		}
		links = append(links, link)
	}
	for _, match := range markdownPattern.FindAllStringSubmatch(body, -1) {
		target, fragment := splitFragment(match[2])
		if strings.Contains(target, "://") {
			continue
		}
		link := &knowledgev1.Link{
			SourceNoteId: sourceID,
			TargetText:   strings.TrimSuffix(target, ".md"),
			Kind:         knowledgev1.LinkKind_LINK_KIND_MARKDOWN,
		}
		if match[1] != "" {
			display := match[1]
			link.DisplayText = &display
		}
		if fragment != "" {
			link.Fragment = &fragment
		}
		links = append(links, link)
	}
	return links
}

func resolveLinks(candidates []candidate) {
	byPath := make(map[string]string)
	byName := make(map[string][]string)
	for _, item := range candidates {
		withoutExtension := strings.TrimSuffix(item.note.Path, ".md")
		byPath[strings.ToLower(withoutExtension)] = item.note.Id
		name := strings.ToLower(filepath.Base(withoutExtension))
		byName[name] = append(byName[name], item.note.Id)
	}

	for _, item := range candidates {
		sourceDir := filepath.ToSlash(filepath.Dir(item.note.Path))
		for _, link := range item.links {
			target := strings.TrimSuffix(filepath.ToSlash(link.TargetText), ".md")
			keys := []string{strings.ToLower(strings.TrimPrefix(target, "/"))}
			if sourceDir != "." {
				keys = append(keys, strings.ToLower(filepath.ToSlash(filepath.Clean(filepath.Join(sourceDir, target)))))
			}
			for _, key := range keys {
				if id, ok := byPath[key]; ok {
					link.ResolvedTargetId = &id
					break
				}
			}
			if link.ResolvedTargetId == nil {
				if ids := byName[strings.ToLower(filepath.Base(target))]; len(ids) == 1 {
					link.ResolvedTargetId = &ids[0]
				}
			}
		}
	}
}

func splitAlias(value string) (string, string) {
	target, display, found := strings.Cut(value, "|")
	if !found {
		return strings.TrimSpace(target), ""
	}
	return strings.TrimSpace(target), strings.TrimSpace(display)
}

func splitFragment(value string) (string, string) {
	target, fragment, found := strings.Cut(value, "#")
	if !found {
		return strings.TrimSpace(target), ""
	}
	return strings.TrimSpace(target), strings.TrimSpace(fragment)
}

func noteID(path string) string {
	sum := sha256.Sum256([]byte(filepath.ToSlash(path)))
	return hex.EncodeToString(sum[:16])
}

func revision(snapshot *knowledgev1.KnowledgeSnapshot) string {
	hash := sha256.New()
	for _, note := range snapshot.Notes {
		fmt.Fprintf(hash, "n\x00%s\x00%s\x00%s\x00%s\x00", note.Id, note.Path, note.Title, note.Body)
		for _, tag := range note.Tags {
			fmt.Fprintf(hash, "t\x00%s\x00", tag)
		}
	}
	for _, link := range snapshot.Links {
		fmt.Fprintf(hash, "l\x00%s\x00%s\x00%s\x00%d\x00", link.SourceNoteId, link.TargetText, link.GetResolvedTargetId(), link.Kind)
	}
	return hex.EncodeToString(hash.Sum(nil))
}
