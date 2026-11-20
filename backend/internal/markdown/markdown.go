// Package markdown extracts Node connections from Markdown bodies.
package markdown

import (
	"regexp"
	"strings"

	nodev2 "github.com/Matey2010/seville/proto/gen/go/seville/node/v2"
)

var (
	wikiPattern     = regexp.MustCompile(`(!?)\[\[([^\]]+)\]\]`)
	markdownPattern = regexp.MustCompile(`!?\[([^\]]*)\]\(([^)]+)\)`)
)

// ExtractConnections returns the wiki, embed, and relative Markdown links in a
// Node body. Targets are unresolved; the store resolves them against slugs.
func ExtractConnections(sourceSlug, body string) []*nodev2.NodeConnection {
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
