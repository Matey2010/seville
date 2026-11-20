package store

import (
	"context"
	"errors"

	nodev2 "github.com/Matey2010/seville/proto/gen/go/seville/node/v2"
	nodesv1 "github.com/Matey2010/seville/proto/gen/go/seville/nodes/v1"
	presentationv1 "github.com/Matey2010/seville/proto/gen/go/seville/presentation/v1"
	systemv1 "github.com/Matey2010/seville/proto/gen/go/seville/system/v1"
)

var ErrSnapshotUnavailable = errors.New("snapshot unavailable")
var ErrNodeNotFound = errors.New("node not found")
var ErrAmbiguousNodeSlug = errors.New("more than one Node has this slug")
var ErrNodeAlreadyExists = errors.New("Node already exists")
var ErrInvalidNodeCreate = errors.New("invalid Node creation")
var ErrInvalidNodeSearchParameter = errors.New("invalid Node search parameter")
var ErrInvalidNodeMutation = errors.New("invalid Node mutation")
var ErrNodeConflict = errors.New("Node changed since it was opened")
var ErrInvalidTemporalSpan = errors.New("invalid Node temporal span")
var ErrInvalidColorRules = errors.New("invalid Node color rules")
var ErrColorRulesConflict = errors.New("Node color rules changed since they were opened")
var ErrInvalidLabel = errors.New("invalid Neo4j label")
var ErrLabelConflict = errors.New("label already exists")
var ErrLabelNotFound = errors.New("label not found")

// NodeCreate describes the caller-owned fields accepted when creating a Node.
// The slug is the Node identity; canonical defaults remain owned by the store.
type NodeCreate struct {
	Slug   string
	Labels []string
	Body   string
}

// NodeMutation describes canonical Node data changes. Additional mutation
// kinds belong here rather than in raw Cypher accepted from an API handler.
type NodeMutation struct {
	SetProperties map[string]any
}

type SnapshotReader interface {
	Snapshot(context.Context) (*nodev2.NodeSnapshot, error)
}

type SystemReader interface {
	SystemInfo(context.Context) (*systemv1.SystemInfo, error)
}

type NodeTreeReader interface {
	NodeTree(context.Context, string, *nodesv1.NodeSearchFilter, nodesv1.NodeRelationshipType, *nodesv1.NodeSearchFilter, uint32) (*nodesv1.NodeTree, error)
}

type NodeSearchReader interface {
	NodeSearch(context.Context, *nodesv1.NodeSearchFilter, uint32) (*nodesv1.NodeSearchResult, error)
}

type NodeGraphReader interface {
	NodeGraph(context.Context, string, string, uint32, uint32) (*nodesv1.NodeGraph, error)
}

type NodeMutator interface {
	MutateNodes(context.Context, *nodesv1.NodeSearchFilter, NodeMutation) (uint64, error)
}

type NodeCreator interface {
	CreateNode(context.Context, NodeCreate) (*nodev2.Node, error)
}

type NodeBodyUpdater interface {
	UpdateNodeBody(context.Context, string, string, uint64) (*nodev2.Node, error)
}

type NodeTemporalUpdater interface {
	ReplaceNodeTemporalSpan(context.Context, string, *nodev2.NodeTemporalSpan, uint64) (*nodev2.Node, error)
}

type LabelStore interface {
	SearchLabels(context.Context, string, uint32) (*nodesv1.LabelSearchResult, error)
	ReplaceNodeLabels(context.Context, string, []string, uint64) (*nodev2.Node, error)
	RenameLabel(context.Context, string, string) (uint64, error)
	DeleteLabel(context.Context, string) (uint64, error)
}

type ColorRuleStore interface {
	NodeColorRules(context.Context) (*presentationv1.NodeColorRuleSet, error)
	ReplaceNodeColorRules(context.Context, *presentationv1.NodeColorRuleSet) (*presentationv1.NodeColorRuleSet, error)
}

type Reader interface {
	SnapshotReader
	SystemReader
	NodeTreeReader
	NodeSearchReader
	NodeGraphReader
}

type NodeService interface {
	Reader
	NodeCreator
	NodeMutator
	NodeBodyUpdater
	NodeTemporalUpdater
	ColorRuleStore
	LabelStore
}

type Backend interface {
	NodeService
	Close() error
}
