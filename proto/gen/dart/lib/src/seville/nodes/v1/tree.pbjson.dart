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
  ],
};

/// Descriptor for `NodeRelationshipType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List nodeRelationshipTypeDescriptor = $convert.base64Decode(
    'ChROb2RlUmVsYXRpb25zaGlwVHlwZRImCiJOT0RFX1JFTEFUSU9OU0hJUF9UWVBFX1VOU1BFQ0'
    'lGSUVEEAASIgoeTk9ERV9SRUxBVElPTlNISVBfVFlQRV9QQVJUX09GEAE=');

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
