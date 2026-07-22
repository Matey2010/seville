// This is a generated file - do not edit.
//
// Generated from seville/node/v2/node.proto.

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

@$core.Deprecated('Use nodeConnectionKindDescriptor instead')
const NodeConnectionKind$json = {
  '1': 'NodeConnectionKind',
  '2': [
    {'1': 'NODE_CONNECTION_KIND_UNSPECIFIED', '2': 0},
    {'1': 'NODE_CONNECTION_KIND_WIKI', '2': 1},
    {'1': 'NODE_CONNECTION_KIND_MARKDOWN', '2': 2},
    {'1': 'NODE_CONNECTION_KIND_EMBED', '2': 3},
  ],
};

/// Descriptor for `NodeConnectionKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List nodeConnectionKindDescriptor = $convert.base64Decode(
    'ChJOb2RlQ29ubmVjdGlvbktpbmQSJAogTk9ERV9DT05ORUNUSU9OX0tJTkRfVU5TUEVDSUZJRU'
    'QQABIdChlOT0RFX0NPTk5FQ1RJT05fS0lORF9XSUtJEAESIQodTk9ERV9DT05ORUNUSU9OX0tJ'
    'TkRfTUFSS0RPV04QAhIeChpOT0RFX0NPTk5FQ1RJT05fS0lORF9FTUJFRBAD');

@$core.Deprecated('Use nodeSnapshotDescriptor instead')
const NodeSnapshot$json = {
  '1': 'NodeSnapshot',
  '2': [
    {'1': 'revision', '3': 1, '4': 1, '5': 9, '10': 'revision'},
    {
      '1': 'generated_at',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'generatedAt'
    },
    {
      '1': 'nodes',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.seville.node.v2.Node',
      '10': 'nodes'
    },
    {
      '1': 'connections',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.seville.node.v2.NodeConnection',
      '10': 'connections'
    },
    {
      '1': 'warnings',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.seville.node.v2.ImportWarning',
      '10': 'warnings'
    },
  ],
};

/// Descriptor for `NodeSnapshot`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeSnapshotDescriptor = $convert.base64Decode(
    'CgxOb2RlU25hcHNob3QSGgoIcmV2aXNpb24YASABKAlSCHJldmlzaW9uEj0KDGdlbmVyYXRlZF'
    '9hdBgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSC2dlbmVyYXRlZEF0EisKBW5v'
    'ZGVzGAMgAygLMhUuc2V2aWxsZS5ub2RlLnYyLk5vZGVSBW5vZGVzEkEKC2Nvbm5lY3Rpb25zGA'
    'QgAygLMh8uc2V2aWxsZS5ub2RlLnYyLk5vZGVDb25uZWN0aW9uUgtjb25uZWN0aW9ucxI6Cgh3'
    'YXJuaW5ncxgFIAMoCzIeLnNldmlsbGUubm9kZS52Mi5JbXBvcnRXYXJuaW5nUgh3YXJuaW5ncw'
    '==');

@$core.Deprecated('Use nodeDescriptor instead')
const Node$json = {
  '1': 'Node',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
    {'1': 'title', '3': 3, '4': 1, '5': 9, '10': 'title'},
    {'1': 'body', '3': 4, '4': 1, '5': 9, '10': 'body'},
    {'1': 'tags', '3': 5, '4': 3, '5': 9, '10': 'tags'},
    {
      '1': 'frontmatter',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.seville.node.v2.Node.FrontmatterEntry',
      '10': 'frontmatter'
    },
    {
      '1': 'modified_at',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'modifiedAt'
    },
    {
      '1': 'emojis',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.seville.node.v2.Emoji',
      '10': 'emojis'
    },
    {'1': 'labels', '3': 9, '4': 3, '5': 9, '10': 'labels'},
    {'1': 'slug', '3': 10, '4': 1, '5': 9, '10': 'slug'},
    {'1': 'update_count', '3': 11, '4': 1, '5': 4, '10': 'updateCount'},
  ],
  '3': [Node_FrontmatterEntry$json],
};

@$core.Deprecated('Use nodeDescriptor instead')
const Node_FrontmatterEntry$json = {
  '1': 'FrontmatterEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `Node`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeDescriptor = $convert.base64Decode(
    'CgROb2RlEg4KAmlkGAEgASgJUgJpZBISCgRwYXRoGAIgASgJUgRwYXRoEhQKBXRpdGxlGAMgAS'
    'gJUgV0aXRsZRISCgRib2R5GAQgASgJUgRib2R5EhIKBHRhZ3MYBSADKAlSBHRhZ3MSSAoLZnJv'
    'bnRtYXR0ZXIYBiADKAsyJi5zZXZpbGxlLm5vZGUudjIuTm9kZS5Gcm9udG1hdHRlckVudHJ5Ug'
    'tmcm9udG1hdHRlchI7Cgttb2RpZmllZF9hdBgHIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l'
    'c3RhbXBSCm1vZGlmaWVkQXQSLgoGZW1vamlzGAggAygLMhYuc2V2aWxsZS5ub2RlLnYyLkVtb2'
    'ppUgZlbW9qaXMSFgoGbGFiZWxzGAkgAygJUgZsYWJlbHMSEgoEc2x1ZxgKIAEoCVIEc2x1ZxIh'
    'Cgx1cGRhdGVfY291bnQYCyABKARSC3VwZGF0ZUNvdW50Gj4KEEZyb250bWF0dGVyRW50cnkSEA'
    'oDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4AQ==');

@$core.Deprecated('Use emojiDescriptor instead')
const Emoji$json = {
  '1': 'Emoji',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'character', '3': 2, '4': 1, '5': 9, '10': 'character'},
    {'1': 'title', '3': 3, '4': 1, '5': 9, '10': 'title'},
    {'1': 'codes', '3': 4, '4': 1, '5': 9, '10': 'codes'},
    {'1': 'group_name', '3': 5, '4': 1, '5': 9, '10': 'groupName'},
    {'1': 'subgroup', '3': 6, '4': 1, '5': 9, '10': 'subgroup'},
    {'1': 'category', '3': 7, '4': 1, '5': 9, '10': 'category'},
    {'1': 'source', '3': 8, '4': 1, '5': 9, '10': 'source'},
    {'1': 'counter', '3': 9, '4': 1, '5': 4, '10': 'counter'},
    {
      '1': 'created_at',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
    {
      '1': 'updated_at',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'updatedAt'
    },
  ],
};

/// Descriptor for `Emoji`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List emojiDescriptor = $convert.base64Decode(
    'CgVFbW9qaRIOCgJpZBgBIAEoCVICaWQSHAoJY2hhcmFjdGVyGAIgASgJUgljaGFyYWN0ZXISFA'
    'oFdGl0bGUYAyABKAlSBXRpdGxlEhQKBWNvZGVzGAQgASgJUgVjb2RlcxIdCgpncm91cF9uYW1l'
    'GAUgASgJUglncm91cE5hbWUSGgoIc3ViZ3JvdXAYBiABKAlSCHN1Ymdyb3VwEhoKCGNhdGVnb3'
    'J5GAcgASgJUghjYXRlZ29yeRIWCgZzb3VyY2UYCCABKAlSBnNvdXJjZRIYCgdjb3VudGVyGAkg'
    'ASgEUgdjb3VudGVyEjkKCmNyZWF0ZWRfYXQYCiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZX'
    'N0YW1wUgljcmVhdGVkQXQSOQoKdXBkYXRlZF9hdBgLIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5U'
    'aW1lc3RhbXBSCXVwZGF0ZWRBdA==');

@$core.Deprecated('Use nodeConnectionDescriptor instead')
const NodeConnection$json = {
  '1': 'NodeConnection',
  '2': [
    {'1': 'source_node_id', '3': 1, '4': 1, '5': 9, '10': 'sourceNodeId'},
    {'1': 'target_text', '3': 2, '4': 1, '5': 9, '10': 'targetText'},
    {
      '1': 'target_node_id',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'targetNodeId',
      '17': true
    },
    {
      '1': 'display_text',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'displayText',
      '17': true
    },
    {
      '1': 'kind',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.seville.node.v2.NodeConnectionKind',
      '10': 'kind'
    },
    {
      '1': 'fragment',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'fragment',
      '17': true
    },
  ],
  '8': [
    {'1': '_target_node_id'},
    {'1': '_display_text'},
    {'1': '_fragment'},
  ],
};

/// Descriptor for `NodeConnection`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeConnectionDescriptor = $convert.base64Decode(
    'Cg5Ob2RlQ29ubmVjdGlvbhIkCg5zb3VyY2Vfbm9kZV9pZBgBIAEoCVIMc291cmNlTm9kZUlkEh'
    '8KC3RhcmdldF90ZXh0GAIgASgJUgp0YXJnZXRUZXh0EikKDnRhcmdldF9ub2RlX2lkGAMgASgJ'
    'SABSDHRhcmdldE5vZGVJZIgBARImCgxkaXNwbGF5X3RleHQYBCABKAlIAVILZGlzcGxheVRleH'
    'SIAQESNwoEa2luZBgFIAEoDjIjLnNldmlsbGUubm9kZS52Mi5Ob2RlQ29ubmVjdGlvbktpbmRS'
    'BGtpbmQSHwoIZnJhZ21lbnQYBiABKAlIAlIIZnJhZ21lbnSIAQFCEQoPX3RhcmdldF9ub2RlX2'
    'lkQg8KDV9kaXNwbGF5X3RleHRCCwoJX2ZyYWdtZW50');

@$core.Deprecated('Use importWarningDescriptor instead')
const ImportWarning$json = {
  '1': 'ImportWarning',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `ImportWarning`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List importWarningDescriptor = $convert.base64Decode(
    'Cg1JbXBvcnRXYXJuaW5nEhIKBHBhdGgYASABKAlSBHBhdGgSGAoHbWVzc2FnZRgCIAEoCVIHbW'
    'Vzc2FnZQ==');

@$core.Deprecated('Use importStatusDescriptor instead')
const ImportStatus$json = {
  '1': 'ImportStatus',
  '2': [
    {'1': 'revision', '3': 1, '4': 1, '5': 9, '10': 'revision'},
    {
      '1': 'imported_at',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'importedAt'
    },
    {'1': 'node_count', '3': 3, '4': 1, '5': 13, '10': 'nodeCount'},
    {'1': 'connection_count', '3': 4, '4': 1, '5': 13, '10': 'connectionCount'},
    {'1': 'warning_count', '3': 5, '4': 1, '5': 13, '10': 'warningCount'},
  ],
};

/// Descriptor for `ImportStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List importStatusDescriptor = $convert.base64Decode(
    'CgxJbXBvcnRTdGF0dXMSGgoIcmV2aXNpb24YASABKAlSCHJldmlzaW9uEjsKC2ltcG9ydGVkX2'
    'F0GAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKaW1wb3J0ZWRBdBIdCgpub2Rl'
    'X2NvdW50GAMgASgNUglub2RlQ291bnQSKQoQY29ubmVjdGlvbl9jb3VudBgEIAEoDVIPY29ubm'
    'VjdGlvbkNvdW50EiMKDXdhcm5pbmdfY291bnQYBSABKA1SDHdhcm5pbmdDb3VudA==');

@$core.Deprecated('Use apiErrorDescriptor instead')
const ApiError$json = {
  '1': 'ApiError',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 9, '10': 'code'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `ApiError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List apiErrorDescriptor = $convert.base64Decode(
    'CghBcGlFcnJvchISCgRjb2RlGAEgASgJUgRjb2RlEhgKB21lc3NhZ2UYAiABKAlSB21lc3NhZ2'
    'U=');
