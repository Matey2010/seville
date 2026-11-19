package scanner

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"slices"
	"strconv"
	"strings"
	"time"

	nodev2 "github.com/Matey2010/seville/proto/gen/go/seville/node/v2"
	"google.golang.org/protobuf/types/known/timestamppb"
	"gopkg.in/yaml.v3"
)

var (
	headingPattern     = regexp.MustCompile(`(?m)^#\s+(.+?)\s*$`)
	wikiPattern        = regexp.MustCompile(`(!?)\[\[([^\]]+)\]\]`)
	markdownPattern    = regexp.MustCompile(`!?\[([^\]]*)\]\(([^)]+)\)`)
	frontmatterPattern = regexp.MustCompile(`(?s)\A---\r?\n(.*?)\r?\n---(?:\r?\n|$)`)
)

type candidate struct {
	node        *nodev2.Node
	connections []*nodev2.NodeConnection
}

func Scan(root string) (*nodev2.NodeSnapshot, error) {
	info, err := os.Stat(root)
	if err != nil {
		return nil, fmt.Errorf("open vault: %w", err)
	}
	if !info.IsDir() {
		return nil, fmt.Errorf("vault path is not a directory")
	}

	var candidates []candidate
	var warnings []*nodev2.ImportWarning
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
			warnings = append(warnings, &nodev2.ImportWarning{Path: relative, Message: err.Error()})
			return nil
		}
		if warning != "" {
			warnings = append(warnings, &nodev2.ImportWarning{Path: relative, Message: warning})
		}
		candidates = append(candidates, parsed)
		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("walk vault: %w", err)
	}

	slices.SortFunc(candidates, func(a, b candidate) int {
		return strings.Compare(a.node.Path, b.node.Path)
	})
	slugs := make(map[string]string, len(candidates))
	for _, item := range candidates {
		if previous, exists := slugs[item.node.Slug]; exists {
			return nil, fmt.Errorf("duplicate slug %q in %s and %s", item.node.Slug, previous, item.node.Path)
		}
		slugs[item.node.Slug] = item.node.Path
	}
	resolveConnections(candidates)

	snapshot := &nodev2.NodeSnapshot{
		GeneratedAt: timestamppb.New(time.Now().UTC()),
		Warnings:    warnings,
	}
	for _, item := range candidates {
		snapshot.Nodes = append(snapshot.Nodes, item.node)
		snapshot.Connections = append(snapshot.Connections, item.connections...)
	}
	snapshot.Revision = revision(snapshot)
	return snapshot, nil
}

func parseFile(path, relative string) (candidate, string, error) {
	content, err := os.ReadFile(path)
	if err != nil {
		return candidate{}, "", fmt.Errorf("read node: %w", err)
	}
	info, err := os.Stat(path)
	if err != nil {
		return candidate{}, "", fmt.Errorf("stat node: %w", err)
	}

	body := string(content)
	typedFrontmatter, bodyWithoutFrontmatter, warning := parseFrontmatter(body)
	for key := range typedFrontmatter {
		if strings.EqualFold(key, "id") || strings.EqualFold(key, "tags") || strings.EqualFold(key, "tags_json") {
			delete(typedFrontmatter, key)
		}
	}
	frontmatter := flattenFrontmatter(typedFrontmatter)
	slug := scalarString(typedFrontmatter["slug"])
	if slug == "" {
		slug = strings.TrimSuffix(relative, filepath.Ext(relative))
	}
	title := scalarString(typedFrontmatter["title"])
	if title == "" {
		if match := headingPattern.FindStringSubmatch(bodyWithoutFrontmatter); match != nil {
			title = strings.TrimSpace(match[1])
		}
	}
	if title == "" {
		title = strings.TrimSuffix(filepath.Base(relative), filepath.Ext(relative))
	}

	node := &nodev2.Node{
		Slug:        slug,
		Path:        relative,
		Title:       title,
		Body:        body,
		Frontmatter: frontmatter,
		ModifiedAt:  timestamppb.New(info.ModTime().UTC()),
	}
	return candidate{node: node, connections: extractConnections(node.Slug, bodyWithoutFrontmatter)}, warning, nil
}

func parseFrontmatter(body string) (map[string]any, string, string) {
	values := make(map[string]any)
	match := frontmatterPattern.FindStringSubmatchIndex(body)
	if match == nil {
		if strings.HasPrefix(body, "---\n") || strings.HasPrefix(body, "---\r\n") {
			return values, body, "frontmatter starts but has no closing delimiter"
		}
		return values, body, ""
	}
	if err := yaml.Unmarshal([]byte(body[match[2]:match[3]]), &values); err != nil {
		return map[string]any{}, body[match[1]:], "invalid YAML frontmatter: " + err.Error()
	}
	return values, body[match[1]:], ""
}

func flattenFrontmatter(values map[string]any) map[string]string {
	flattened := make(map[string]string, len(values))
	for key, value := range values {
		if text := scalarString(value); text != "" {
			flattened[key] = text
			continue
		}
		if items, ok := value.([]any); ok {
			parts := make([]string, 0, len(items))
			for _, item := range items {
				if text := scalarString(item); text != "" {
					parts = append(parts, text)
				}
			}
			if len(parts) == len(items) {
				flattened[key] = strings.Join(parts, ",")
				continue
			}
		}
		if encoded, err := json.Marshal(value); err == nil {
			flattened[key] = string(encoded)
		}
	}
	return flattened
}

func scalarString(value any) string {
	switch typed := value.(type) {
	case string:
		return strings.TrimSpace(typed)
	case int:
		return strconv.Itoa(typed)
	case int64:
		return strconv.FormatInt(typed, 10)
	case uint64:
		return strconv.FormatUint(typed, 10)
	case float64:
		return strconv.FormatFloat(typed, 'g', -1, 64)
	case bool:
		return strconv.FormatBool(typed)
	default:
		return ""
	}
}

func extractConnections(sourceSlug, body string) []*nodev2.NodeConnection {
	var connections []*nodev2.NodeConnection
	for _, match := range wikiPattern.FindAllStringSubmatch(body, -1) {
		target, display := splitAlias(match[2])
		target, fragment := splitFragment(target)
		kind := nodev2.NodeConnectionKind_NODE_CONNECTION_KIND_WIKI
		if match[1] == "!" {
			kind = nodev2.NodeConnectionKind_NODE_CONNECTION_KIND_EMBED
		}
		connection := &nodev2.NodeConnection{SourceNodeSlug: sourceSlug, TargetText: target, Kind: kind}
		if display != "" {
			connection.DisplayText = &display
		}
		if fragment != "" {
			connection.Fragment = &fragment
		}
		connections = append(connections, connection)
	}
	for _, match := range markdownPattern.FindAllStringSubmatch(body, -1) {
		target, fragment := splitFragment(match[2])
		if strings.Contains(target, "://") {
			continue
		}
		connection := &nodev2.NodeConnection{
			SourceNodeSlug: sourceSlug,
			TargetText:     strings.TrimSuffix(target, ".md"),
			Kind:           nodev2.NodeConnectionKind_NODE_CONNECTION_KIND_MARKDOWN,
		}
		if match[1] != "" {
			display := match[1]
			connection.DisplayText = &display
		}
		if fragment != "" {
			connection.Fragment = &fragment
		}
		connections = append(connections, connection)
	}
	return connections
}

// ExtractConnections uses the same Markdown connection syntax for imported
// source documents and canonical Node body edits.
func ExtractConnections(sourceSlug, body string) []*nodev2.NodeConnection {
	return extractConnections(sourceSlug, body)
}

func resolveConnections(candidates []candidate) {
	byPath := make(map[string]string)
	byName := make(map[string][]string)
	for _, item := range candidates {
		withoutExtension := strings.TrimSuffix(item.node.Path, ".md")
		byPath[strings.ToLower(withoutExtension)] = item.node.Slug
		name := strings.ToLower(filepath.Base(withoutExtension))
		byName[name] = append(byName[name], item.node.Slug)
	}

	for _, item := range candidates {
		sourceDir := filepath.ToSlash(filepath.Dir(item.node.Path))
		for _, connection := range item.connections {
			target := strings.TrimSuffix(filepath.ToSlash(connection.TargetText), ".md")
			keys := []string{strings.ToLower(strings.TrimPrefix(target, "/"))}
			if sourceDir != "." {
				keys = append(keys, strings.ToLower(filepath.ToSlash(filepath.Clean(filepath.Join(sourceDir, target)))))
			}
			for _, key := range keys {
				if slug, ok := byPath[key]; ok {
					connection.TargetNodeSlug = &slug
					break
				}
			}
			if connection.TargetNodeSlug == nil {
				if slugs := byName[strings.ToLower(filepath.Base(target))]; len(slugs) == 1 {
					connection.TargetNodeSlug = &slugs[0]
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

func revision(snapshot *nodev2.NodeSnapshot) string {
	hash := sha256.New()
	for _, node := range snapshot.Nodes {
		fmt.Fprintf(hash, "n\x00%s\x00%s\x00%s\x00%s\x00", node.Slug, node.Path, node.Title, node.Body)
	}
	for _, connection := range snapshot.Connections {
		fmt.Fprintf(hash, "l\x00%s\x00%s\x00%s\x00%d\x00", connection.SourceNodeSlug, connection.TargetText, connection.GetTargetNodeSlug(), connection.Kind)
	}
	return hex.EncodeToString(hash.Sum(nil))
}
