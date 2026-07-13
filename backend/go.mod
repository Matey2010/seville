module github.com/Matey2010/seville/backend

go 1.24.0

require (
	github.com/Matey2010/seville/proto/gen/go v0.0.0
	github.com/neo4j/neo4j-go-driver/v6 v6.2.0
	google.golang.org/protobuf v1.36.11
	gopkg.in/yaml.v3 v3.0.1
)

replace github.com/Matey2010/seville/proto/gen/go => ../proto/gen/go
