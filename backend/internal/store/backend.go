package store

import (
	"context"
	"errors"

	nodev2 "github.com/Matey2010/seville/proto/gen/go/seville/node/v2"
	nodesv1 "github.com/Matey2010/seville/proto/gen/go/seville/nodes/v1"
	systemv1 "github.com/Matey2010/seville/proto/gen/go/seville/system/v1"
)

var ErrSnapshotUnavailable = errors.New("snapshot unavailable")
var ErrNodeNotFound = errors.New("node not found")
var ErrNodeAlreadyExists = errors.New("Node already exists")
var ErrInvalidNodeCreate = errors.New("invalid Node creation")
var ErrInvalidNodeSearchParameter = errors.New("invalid Node search parameter")
var ErrInvalidNodeMutation = errors.New("invalid Node mutation")

// NodeCreate describes the caller-owned fields accepted when creating a Node.
// Stable identity and canonical defaults remain owned by the store.
type NodeCreate struct {
	Slug   string
	Labels []string
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

type NodeMutator interface {
	MutateNodes(context.Context, *nodesv1.NodeSearchFilter, NodeMutation) (uint64, error)
}

type NodeCreator interface {
	CreateNode(context.Context, NodeCreate) (*nodev2.Node, error)
}

type Reader interface {
	SnapshotReader
	SystemReader
	NodeTreeReader
	NodeSearchReader
}

type NodeService interface {
	Reader
	NodeCreator
	NodeMutator
}

type Importer interface {
	ImportNew(context.Context, *nodev2.NodeSnapshot) error
}

type Backend interface {
	NodeService
	Importer
	Close() error
}
