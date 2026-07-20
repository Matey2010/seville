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
var ErrInvalidNodeSearchParameter = errors.New("invalid Node search parameter")

type SnapshotReader interface {
	Snapshot(context.Context) (*nodev2.NodeSnapshot, error)
}

type SystemReader interface {
	SystemInfo(context.Context) (*systemv1.SystemInfo, error)
}

type NodeTreeReader interface {
	NodeTree(context.Context, string, nodesv1.NodeRelationshipType, *nodesv1.NodeSearchFilter, uint32) (*nodesv1.NodeTree, error)
}

type Reader interface {
	SnapshotReader
	SystemReader
	NodeTreeReader
}

type Importer interface {
	ImportNew(context.Context, *nodev2.NodeSnapshot) error
}

type Backend interface {
	Reader
	Importer
	Close() error
}
