package store

import (
	"context"
	"errors"

	knowledgev1 "github.com/Matey2010/seville/proto/gen/go/seville/knowledge/v1"
)

var ErrSnapshotUnavailable = errors.New("snapshot unavailable")

type Backend interface {
	ImportNew(context.Context, *knowledgev1.KnowledgeSnapshot) error
	Snapshot(context.Context) (*knowledgev1.KnowledgeSnapshot, error)
	Close() error
}
