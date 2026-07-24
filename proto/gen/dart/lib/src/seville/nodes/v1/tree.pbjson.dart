// This is a generated file - do not edit.
//
// Generated from seville/nodes/v1/tree.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use nodeRelationshipTypeDescriptor instead')
const NodeRelationshipType$json = {
  '1': 'NodeRelationshipType',
  '2': [
    {'1': 'NODE_RELATIONSHIP_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'NODE_RELATIONSHIP_TYPE_PART_OF', '2': 1},
    {'1': 'NODE_RELATIONSHIP_TYPE_FAMILY', '2': 2},
  ],
};

/// Descriptor for `NodeRelationshipType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List nodeRelationshipTypeDescriptor = $convert.base64Decode(
    'ChROb2RlUmVsYXRpb25zaGlwVHlwZRImCiJOT0RFX1JFTEFUSU9OU0hJUF9UWVBFX1VOU1BFQ0'
    'lGSUVEEAASIgoeTk9ERV9SRUxBVElPTlNISVBfVFlQRV9QQVJUX09GEAESIQodTk9ERV9SRUxB'
    'VElPTlNISVBfVFlQRV9GQU1JTFkQAg==');

@$core.Deprecated('Use nodeParameterTypeDescriptor instead')
const NodeParameterType$json = {
  '1': 'NodeParameterType',
  '2': [
    {'1': 'NODE_PARAMETER_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'NODE_PARAMETER_TYPE_NAME', '2': 1},
    {'1': 'NODE_PARAMETER_TYPE_ID', '2': 2},
    {'1': 'NODE_PARAMETER_TYPE_PATH', '2': 3},
    {'1': 'NODE_PARAMETER_TYPE_TITLE', '2': 4},
    {'1': 'NODE_PARAMETER_TYPE_TAG', '2': 5},
    {'1': 'NODE_PARAMETER_TYPE_LABEL', '2': 6},
    {'1': 'NODE_PARAMETER_TYPE_SLUG', '2': 7},
  ],
};

/// Descriptor for `NodeParameterType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List nodeParameterTypeDescriptor = $convert.base64Decode(
    'ChFOb2RlUGFyYW1ldGVyVHlwZRIjCh9OT0RFX1BBUkFNRVRFUl9UWVBFX1VOU1BFQ0lGSUVEEA'
    'ASHAoYTk9ERV9QQVJBTUVURVJfVFlQRV9OQU1FEAESGgoWTk9ERV9QQVJBTUVURVJfVFlQRV9J'
    'RBACEhwKGE5PREVfUEFSQU1FVEVSX1RZUEVfUEFUSBADEh0KGU5PREVfUEFSQU1FVEVSX1RZUE'
    'VfVElUTEUQBBIbChdOT0RFX1BBUkFNRVRFUl9UWVBFX1RBRxAFEh0KGU5PREVfUEFSQU1FVEVS'
    'X1RZUEVfTEFCRUwQBhIcChhOT0RFX1BBUkFNRVRFUl9UWVBFX1NMVUcQBw==');

@$core.Deprecated('Use nodeSearchMatchOperatorDescriptor instead')
const NodeSearchMatchOperator$json = {
  '1': 'NodeSearchMatchOperator',
  '2': [
    {'1': 'NODE_SEARCH_MATCH_OPERATOR_UNSPECIFIED', '2': 0},
    {'1': 'NODE_SEARCH_MATCH_OPERATOR_EXACT', '2': 1},
    {'1': 'NODE_SEARCH_MATCH_OPERATOR_REGULAR_EXPRESSION', '2': 2},
    {'1': 'NODE_SEARCH_MATCH_OPERATOR_STARTS_WITH', '2': 3},
    {'1': 'NODE_SEARCH_MATCH_OPERATOR_ENDS_WITH', '2': 4},
    {'1': 'NODE_SEARCH_MATCH_OPERATOR_CONTAINS', '2': 5},
  ],
};

/// Descriptor for `NodeSearchMatchOperator`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List nodeSearchMatchOperatorDescriptor = $convert.base64Decode(
    'ChdOb2RlU2VhcmNoTWF0Y2hPcGVyYXRvchIqCiZOT0RFX1NFQVJDSF9NQVRDSF9PUEVSQVRPUl'
    '9VTlNQRUNJRklFRBAAEiQKIE5PREVfU0VBUkNIX01BVENIX09QRVJBVE9SX0VYQUNUEAESMQot'
    'Tk9ERV9TRUFSQ0hfTUFUQ0hfT1BFUkFUT1JfUkVHVUxBUl9FWFBSRVNTSU9OEAISKgomTk9ERV'
    '9TRUFSQ0hfTUFUQ0hfT1BFUkFUT1JfU1RBUlRTX1dJVEgQAxIoCiROT0RFX1NFQVJDSF9NQVRD'
    'SF9PUEVSQVRPUl9FTkRTX1dJVEgQBBInCiNOT0RFX1NFQVJDSF9NQVRDSF9PUEVSQVRPUl9DT0'
    '5UQUlOUxAF');

@$core.Deprecated('Use nodeSearchMatchModeDescriptor instead')
const NodeSearchMatchMode$json = {
  '1': 'NodeSearchMatchMode',
  '2': [
    {'1': 'NODE_SEARCH_MATCH_MODE_UNSPECIFIED', '2': 0},
    {'1': 'NODE_SEARCH_MATCH_MODE_ANY', '2': 1},
    {'1': 'NODE_SEARCH_MATCH_MODE_ALL', '2': 2},
  ],
};

/// Descriptor for `NodeSearchMatchMode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List nodeSearchMatchModeDescriptor = $convert.base64Decode(
    'ChNOb2RlU2VhcmNoTWF0Y2hNb2RlEiYKIk5PREVfU0VBUkNIX01BVENIX01PREVfVU5TUEVDSU'
    'ZJRUQQABIeChpOT0RFX1NFQVJDSF9NQVRDSF9NT0RFX0FOWRABEh4KGk5PREVfU0VBUkNIX01B'
    'VENIX01PREVfQUxMEAI=');

@$core.Deprecated('Use nodeSearchParameterDescriptor instead')
const NodeSearchParameter$json = {
  '1': 'NodeSearchParameter',
  '2': [
    {
      '1': 'parameter',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.seville.nodes.v1.NodeParameterType',
      '10': 'parameter'
    },
    {
      '1': 'operator',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.seville.nodes.v1.NodeSearchMatchOperator',
      '10': 'operator'
    },
    {'1': 'string_value', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'stringValue'},
  ],
  '8': [
    {'1': 'value'},
  ],
};

/// Descriptor for `NodeSearchParameter`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeSearchParameterDescriptor = $convert.base64Decode(
    'ChNOb2RlU2VhcmNoUGFyYW1ldGVyEkEKCXBhcmFtZXRlchgBIAEoDjIjLnNldmlsbGUubm9kZX'
    'MudjEuTm9kZVBhcmFtZXRlclR5cGVSCXBhcmFtZXRlchJFCghvcGVyYXRvchgCIAEoDjIpLnNl'
    'dmlsbGUubm9kZXMudjEuTm9kZVNlYXJjaE1hdGNoT3BlcmF0b3JSCG9wZXJhdG9yEiMKDHN0cm'
    'luZ192YWx1ZRgDIAEoCUgAUgtzdHJpbmdWYWx1ZUIHCgV2YWx1ZQ==');

@$core.Deprecated('Use nodeSearchFilterDescriptor instead')
const NodeSearchFilter$json = {
  '1': 'NodeSearchFilter',
  '2': [
    {
      '1': 'include_nodes_matching',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.seville.nodes.v1.NodeSearchParameter',
      '10': 'includeNodesMatching'
    },
    {
      '1': 'exclude_nodes_matching',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.seville.nodes.v1.NodeSearchParameter',
      '10': 'excludeNodesMatching'
    },
    {
      '1': 'include_match_mode',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.seville.nodes.v1.NodeSearchMatchMode',
      '10': 'includeMatchMode'
    },
    {'1': 'negated', '3': 4, '4': 1, '5': 8, '10': 'negated'},
  ],
};

/// Descriptor for `NodeSearchFilter`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeSearchFilterDescriptor = $convert.base64Decode(
    'ChBOb2RlU2VhcmNoRmlsdGVyElsKFmluY2x1ZGVfbm9kZXNfbWF0Y2hpbmcYASADKAsyJS5zZX'
    'ZpbGxlLm5vZGVzLnYxLk5vZGVTZWFyY2hQYXJhbWV0ZXJSFGluY2x1ZGVOb2Rlc01hdGNoaW5n'
    'ElsKFmV4Y2x1ZGVfbm9kZXNfbWF0Y2hpbmcYAiADKAsyJS5zZXZpbGxlLm5vZGVzLnYxLk5vZG'
    'VTZWFyY2hQYXJhbWV0ZXJSFGV4Y2x1ZGVOb2Rlc01hdGNoaW5nElMKEmluY2x1ZGVfbWF0Y2hf'
    'bW9kZRgDIAEoDjIlLnNldmlsbGUubm9kZXMudjEuTm9kZVNlYXJjaE1hdGNoTW9kZVIQaW5jbH'
    'VkZU1hdGNoTW9kZRIYCgduZWdhdGVkGAQgASgIUgduZWdhdGVk');

@$core.Deprecated('Use nodeSearchQueryDescriptor instead')
const NodeSearchQuery$json = {
  '1': 'NodeSearchQuery',
  '2': [
    {
      '1': 'node_filter',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.seville.nodes.v1.NodeSearchFilter',
      '10': 'nodeFilter'
    },
    {'1': 'limit', '3': 2, '4': 1, '5': 13, '9': 0, '10': 'limit', '17': true},
  ],
  '8': [
    {'1': '_limit'},
  ],
};

/// Descriptor for `NodeSearchQuery`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeSearchQueryDescriptor = $convert.base64Decode(
    'Cg9Ob2RlU2VhcmNoUXVlcnkSQwoLbm9kZV9maWx0ZXIYASABKAsyIi5zZXZpbGxlLm5vZGVzLn'
    'YxLk5vZGVTZWFyY2hGaWx0ZXJSCm5vZGVGaWx0ZXISGQoFbGltaXQYAiABKA1IAFIFbGltaXSI'
    'AQFCCAoGX2xpbWl0');

@$core.Deprecated('Use nodeSearchResultDescriptor instead')
const NodeSearchResult$json = {
  '1': 'NodeSearchResult',
  '2': [
    {
      '1': 'nodes',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.seville.node.v2.Node',
      '10': 'nodes'
    },
  ],
};

/// Descriptor for `NodeSearchResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeSearchResultDescriptor = $convert.base64Decode(
    'ChBOb2RlU2VhcmNoUmVzdWx0EisKBW5vZGVzGAEgAygLMhUuc2V2aWxsZS5ub2RlLnYyLk5vZG'
    'VSBW5vZGVz');

@$core.Deprecated('Use nodeCreateRequestDescriptor instead')
const NodeCreateRequest$json = {
  '1': 'NodeCreateRequest',
  '2': [
    {'1': 'slug', '3': 1, '4': 1, '5': 9, '10': 'slug'},
    {'1': 'labels', '3': 2, '4': 3, '5': 9, '10': 'labels'},
  ],
};

/// Descriptor for `NodeCreateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeCreateRequestDescriptor = $convert.base64Decode(
    'ChFOb2RlQ3JlYXRlUmVxdWVzdBISCgRzbHVnGAEgASgJUgRzbHVnEhYKBmxhYmVscxgCIAMoCV'
    'IGbGFiZWxz');

@$core.Deprecated('Use nodePropertyValueDescriptor instead')
const NodePropertyValue$json = {
  '1': 'NodePropertyValue',
  '2': [
    {'1': 'string_value', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'stringValue'},
    {
      '1': 'integer_value',
      '3': 2,
      '4': 1,
      '5': 3,
      '9': 0,
      '10': 'integerValue'
    },
    {'1': 'double_value', '3': 3, '4': 1, '5': 1, '9': 0, '10': 'doubleValue'},
    {
      '1': 'boolean_value',
      '3': 4,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'booleanValue'
    },
  ],
  '8': [
    {'1': 'value'},
  ],
};

/// Descriptor for `NodePropertyValue`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodePropertyValueDescriptor = $convert.base64Decode(
    'ChFOb2RlUHJvcGVydHlWYWx1ZRIjCgxzdHJpbmdfdmFsdWUYASABKAlIAFILc3RyaW5nVmFsdW'
    'USJQoNaW50ZWdlcl92YWx1ZRgCIAEoA0gAUgxpbnRlZ2VyVmFsdWUSIwoMZG91YmxlX3ZhbHVl'
    'GAMgASgBSABSC2RvdWJsZVZhbHVlEiUKDWJvb2xlYW5fdmFsdWUYBCABKAhIAFIMYm9vbGVhbl'
    'ZhbHVlQgcKBXZhbHVl');

@$core.Deprecated('Use nodeMutationRequestDescriptor instead')
const NodeMutationRequest$json = {
  '1': 'NodeMutationRequest',
  '2': [
    {
      '1': 'node_filter',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.seville.nodes.v1.NodeSearchFilter',
      '10': 'nodeFilter'
    },
    {
      '1': 'set_properties',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.seville.nodes.v1.NodeMutationRequest.SetPropertiesEntry',
      '10': 'setProperties'
    },
    {
      '1': 'remove_properties',
      '3': 3,
      '4': 3,
      '5': 9,
      '10': 'removeProperties'
    },
  ],
  '3': [NodeMutationRequest_SetPropertiesEntry$json],
};

@$core.Deprecated('Use nodeMutationRequestDescriptor instead')
const NodeMutationRequest_SetPropertiesEntry$json = {
  '1': 'SetPropertiesEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.seville.nodes.v1.NodePropertyValue',
      '10': 'value'
    },
  ],
  '7': {'7': true},
};

/// Descriptor for `NodeMutationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeMutationRequestDescriptor = $convert.base64Decode(
    'ChNOb2RlTXV0YXRpb25SZXF1ZXN0EkMKC25vZGVfZmlsdGVyGAEgASgLMiIuc2V2aWxsZS5ub2'
    'Rlcy52MS5Ob2RlU2VhcmNoRmlsdGVyUgpub2RlRmlsdGVyEl8KDnNldF9wcm9wZXJ0aWVzGAIg'
    'AygLMjguc2V2aWxsZS5ub2Rlcy52MS5Ob2RlTXV0YXRpb25SZXF1ZXN0LlNldFByb3BlcnRpZX'
    'NFbnRyeVINc2V0UHJvcGVydGllcxIrChFyZW1vdmVfcHJvcGVydGllcxgDIAMoCVIQcmVtb3Zl'
    'UHJvcGVydGllcxplChJTZXRQcm9wZXJ0aWVzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSOQoFdm'
    'FsdWUYAiABKAsyIy5zZXZpbGxlLm5vZGVzLnYxLk5vZGVQcm9wZXJ0eVZhbHVlUgV2YWx1ZToC'
    'OAE=');

@$core.Deprecated('Use nodeMutationResultDescriptor instead')
const NodeMutationResult$json = {
  '1': 'NodeMutationResult',
  '2': [
    {
      '1': 'mutated_node_count',
      '3': 1,
      '4': 1,
      '5': 4,
      '10': 'mutatedNodeCount'
    },
  ],
};

/// Descriptor for `NodeMutationResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeMutationResultDescriptor = $convert.base64Decode(
    'ChJOb2RlTXV0YXRpb25SZXN1bHQSLAoSbXV0YXRlZF9ub2RlX2NvdW50GAEgASgEUhBtdXRhdG'
    'VkTm9kZUNvdW50');

@$core.Deprecated('Use nodeTreeQueryDescriptor instead')
const NodeTreeQuery$json = {
  '1': 'NodeTreeQuery',
  '2': [
    {
      '1': 'root_node_id',
      '3': 1,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'rootNodeId',
      '17': true
    },
    {'1': 'depth', '3': 2, '4': 1, '5': 13, '9': 1, '10': 'depth', '17': true},
    {
      '1': 'traverse_by',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.seville.nodes.v1.NodeRelationshipType',
      '10': 'traverseBy'
    },
    {
      '1': 'node_filter',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.seville.nodes.v1.NodeSearchFilter',
      '9': 2,
      '10': 'nodeFilter',
      '17': true
    },
    {
      '1': 'root_node_filter',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.seville.nodes.v1.NodeSearchFilter',
      '9': 3,
      '10': 'rootNodeFilter',
      '17': true
    },
  ],
  '8': [
    {'1': '_root_node_id'},
    {'1': '_depth'},
    {'1': '_node_filter'},
    {'1': '_root_node_filter'},
  ],
};

/// Descriptor for `NodeTreeQuery`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeTreeQueryDescriptor = $convert.base64Decode(
    'Cg1Ob2RlVHJlZVF1ZXJ5EiUKDHJvb3Rfbm9kZV9pZBgBIAEoCUgAUgpyb290Tm9kZUlkiAEBEh'
    'kKBWRlcHRoGAIgASgNSAFSBWRlcHRoiAEBEkcKC3RyYXZlcnNlX2J5GAMgASgOMiYuc2V2aWxs'
    'ZS5ub2Rlcy52MS5Ob2RlUmVsYXRpb25zaGlwVHlwZVIKdHJhdmVyc2VCeRJICgtub2RlX2ZpbH'
    'RlchgEIAEoCzIiLnNldmlsbGUubm9kZXMudjEuTm9kZVNlYXJjaEZpbHRlckgCUgpub2RlRmls'
    'dGVyiAEBElEKEHJvb3Rfbm9kZV9maWx0ZXIYBSABKAsyIi5zZXZpbGxlLm5vZGVzLnYxLk5vZG'
    'VTZWFyY2hGaWx0ZXJIA1IOcm9vdE5vZGVGaWx0ZXKIAQFCDwoNX3Jvb3Rfbm9kZV9pZEIICgZf'
    'ZGVwdGhCDgoMX25vZGVfZmlsdGVyQhMKEV9yb290X25vZGVfZmlsdGVy');

@$core.Deprecated('Use nodeTreeOccurrenceDescriptor instead')
const NodeTreeOccurrence$json = {
  '1': 'NodeTreeOccurrence',
  '2': [
    {'1': 'occurrence_id', '3': 1, '4': 1, '5': 9, '10': 'occurrenceId'},
    {
      '1': 'parent_occurrence_id',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'parentOccurrenceId',
      '17': true
    },
    {'1': 'depth', '3': 3, '4': 1, '5': 13, '10': 'depth'},
    {
      '1': 'node',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.seville.node.v2.Node',
      '10': 'node'
    },
  ],
  '8': [
    {'1': '_parent_occurrence_id'},
  ],
};

/// Descriptor for `NodeTreeOccurrence`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeTreeOccurrenceDescriptor = $convert.base64Decode(
    'ChJOb2RlVHJlZU9jY3VycmVuY2USIwoNb2NjdXJyZW5jZV9pZBgBIAEoCVIMb2NjdXJyZW5jZU'
    'lkEjUKFHBhcmVudF9vY2N1cnJlbmNlX2lkGAIgASgJSABSEnBhcmVudE9jY3VycmVuY2VJZIgB'
    'ARIUCgVkZXB0aBgDIAEoDVIFZGVwdGgSKQoEbm9kZRgEIAEoCzIVLnNldmlsbGUubm9kZS52Mi'
    '5Ob2RlUgRub2RlQhcKFV9wYXJlbnRfb2NjdXJyZW5jZV9pZA==');

@$core.Deprecated('Use nodeTreeDescriptor instead')
const NodeTree$json = {
  '1': 'NodeTree',
  '2': [
    {'1': 'root_node_id', '3': 1, '4': 1, '5': 9, '10': 'rootNodeId'},
    {
      '1': 'relationship',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.seville.nodes.v1.NodeRelationshipType',
      '10': 'relationship'
    },
    {'1': 'depth', '3': 3, '4': 1, '5': 13, '10': 'depth'},
    {
      '1': 'occurrences',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.seville.nodes.v1.NodeTreeOccurrence',
      '10': 'occurrences'
    },
  ],
};

/// Descriptor for `NodeTree`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeTreeDescriptor = $convert.base64Decode(
    'CghOb2RlVHJlZRIgCgxyb290X25vZGVfaWQYASABKAlSCnJvb3ROb2RlSWQSSgoMcmVsYXRpb2'
    '5zaGlwGAIgASgOMiYuc2V2aWxsZS5ub2Rlcy52MS5Ob2RlUmVsYXRpb25zaGlwVHlwZVIMcmVs'
    'YXRpb25zaGlwEhQKBWRlcHRoGAMgASgNUgVkZXB0aBJGCgtvY2N1cnJlbmNlcxgEIAMoCzIkLn'
    'NldmlsbGUubm9kZXMudjEuTm9kZVRyZWVPY2N1cnJlbmNlUgtvY2N1cnJlbmNlcw==');
