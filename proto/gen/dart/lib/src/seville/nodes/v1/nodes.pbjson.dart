// This is a generated file - do not edit.
//
// Generated from seville/nodes/v1/nodes.proto.

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

@$core.Deprecated('Use nodeParameterTypeDescriptor instead')
const NodeParameterType$json = {
  '1': 'NodeParameterType',
  '2': [
    {'1': 'NODE_PARAMETER_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'NODE_PARAMETER_TYPE_NAME', '2': 1},
    {'1': 'NODE_PARAMETER_TYPE_PATH', '2': 3},
    {'1': 'NODE_PARAMETER_TYPE_TITLE', '2': 4},
    {'1': 'NODE_PARAMETER_TYPE_LABEL', '2': 6},
    {'1': 'NODE_PARAMETER_TYPE_SLUG', '2': 7},
  ],
  '4': [
    {'1': 2, '2': 2},
    {'1': 5, '2': 5},
  ],
  '5': ['NODE_PARAMETER_TYPE_ID', 'NODE_PARAMETER_TYPE_TAG'],
};

/// Descriptor for `NodeParameterType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List nodeParameterTypeDescriptor = $convert.base64Decode(
    'ChFOb2RlUGFyYW1ldGVyVHlwZRIjCh9OT0RFX1BBUkFNRVRFUl9UWVBFX1VOU1BFQ0lGSUVEEA'
    'ASHAoYTk9ERV9QQVJBTUVURVJfVFlQRV9OQU1FEAESHAoYTk9ERV9QQVJBTUVURVJfVFlQRV9Q'
    'QVRIEAMSHQoZTk9ERV9QQVJBTUVURVJfVFlQRV9USVRMRRAEEh0KGU5PREVfUEFSQU1FVEVSX1'
    'RZUEVfTEFCRUwQBhIcChhOT0RFX1BBUkFNRVRFUl9UWVBFX1NMVUcQByIECAIQAiIECAUQBSoW'
    'Tk9ERV9QQVJBTUVURVJfVFlQRV9JRCoXTk9ERV9QQVJBTUVURVJfVFlQRV9UQUc=');

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
    {'1': 'body', '3': 3, '4': 1, '5': 9, '10': 'body'},
  ],
};

/// Descriptor for `NodeCreateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeCreateRequestDescriptor = $convert.base64Decode(
    'ChFOb2RlQ3JlYXRlUmVxdWVzdBISCgRzbHVnGAEgASgJUgRzbHVnEhYKBmxhYmVscxgCIAMoCV'
    'IGbGFiZWxzEhIKBGJvZHkYAyABKAlSBGJvZHk=');

@$core.Deprecated('Use nodeGraphQueryDescriptor instead')
const NodeGraphQuery$json = {
  '1': 'NodeGraphQuery',
  '2': [
    {
      '1': 'root_node_slug',
      '3': 1,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'rootNodeSlug',
      '17': true
    },
    {'1': 'depth', '3': 2, '4': 1, '5': 13, '10': 'depth'},
    {'1': 'limit', '3': 3, '4': 1, '5': 13, '10': 'limit'},
    {'1': 'search', '3': 4, '4': 1, '5': 9, '10': 'search'},
  ],
  '8': [
    {'1': '_root_node_slug'},
  ],
};

/// Descriptor for `NodeGraphQuery`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeGraphQueryDescriptor = $convert.base64Decode(
    'Cg5Ob2RlR3JhcGhRdWVyeRIpCg5yb290X25vZGVfc2x1ZxgBIAEoCUgAUgxyb290Tm9kZVNsdW'
    'eIAQESFAoFZGVwdGgYAiABKA1SBWRlcHRoEhQKBWxpbWl0GAMgASgNUgVsaW1pdBIWCgZzZWFy'
    'Y2gYBCABKAlSBnNlYXJjaEIRCg9fcm9vdF9ub2RlX3NsdWc=');

@$core.Deprecated('Use nodeGraphDescriptor instead')
const NodeGraph$json = {
  '1': 'NodeGraph',
  '2': [
    {
      '1': 'nodes',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.seville.node.v2.Node',
      '10': 'nodes'
    },
    {
      '1': 'connections',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.seville.node.v2.NodeConnection',
      '10': 'connections'
    },
    {'1': 'has_more', '3': 3, '4': 1, '5': 8, '10': 'hasMore'},
  ],
};

/// Descriptor for `NodeGraph`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeGraphDescriptor = $convert.base64Decode(
    'CglOb2RlR3JhcGgSKwoFbm9kZXMYASADKAsyFS5zZXZpbGxlLm5vZGUudjIuTm9kZVIFbm9kZX'
    'MSQQoLY29ubmVjdGlvbnMYAiADKAsyHy5zZXZpbGxlLm5vZGUudjIuTm9kZUNvbm5lY3Rpb25S'
    'C2Nvbm5lY3Rpb25zEhkKCGhhc19tb3JlGAMgASgIUgdoYXNNb3Jl');

@$core.Deprecated('Use nodeBodyUpdateRequestDescriptor instead')
const NodeBodyUpdateRequest$json = {
  '1': 'NodeBodyUpdateRequest',
  '2': [
    {'1': 'body', '3': 1, '4': 1, '5': 9, '10': 'body'},
    {
      '1': 'expected_update_count',
      '3': 2,
      '4': 1,
      '5': 4,
      '10': 'expectedUpdateCount'
    },
  ],
};

/// Descriptor for `NodeBodyUpdateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeBodyUpdateRequestDescriptor = $convert.base64Decode(
    'ChVOb2RlQm9keVVwZGF0ZVJlcXVlc3QSEgoEYm9keRgBIAEoCVIEYm9keRIyChVleHBlY3RlZF'
    '91cGRhdGVfY291bnQYAiABKARSE2V4cGVjdGVkVXBkYXRlQ291bnQ=');

@$core.Deprecated('Use nodeTemporalUpdateRequestDescriptor instead')
const NodeTemporalUpdateRequest$json = {
  '1': 'NodeTemporalUpdateRequest',
  '2': [
    {
      '1': 'span',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.seville.node.v2.NodeTemporalSpan',
      '10': 'span'
    },
    {
      '1': 'expected_update_count',
      '3': 2,
      '4': 1,
      '5': 4,
      '10': 'expectedUpdateCount'
    },
  ],
};

/// Descriptor for `NodeTemporalUpdateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeTemporalUpdateRequestDescriptor = $convert.base64Decode(
    'ChlOb2RlVGVtcG9yYWxVcGRhdGVSZXF1ZXN0EjUKBHNwYW4YASABKAsyIS5zZXZpbGxlLm5vZG'
    'UudjIuTm9kZVRlbXBvcmFsU3BhblIEc3BhbhIyChVleHBlY3RlZF91cGRhdGVfY291bnQYAiAB'
    'KARSE2V4cGVjdGVkVXBkYXRlQ291bnQ=');

@$core.Deprecated('Use nodeLabelsUpdateRequestDescriptor instead')
const NodeLabelsUpdateRequest$json = {
  '1': 'NodeLabelsUpdateRequest',
  '2': [
    {'1': 'labels', '3': 1, '4': 3, '5': 9, '10': 'labels'},
    {
      '1': 'expected_update_count',
      '3': 2,
      '4': 1,
      '5': 4,
      '10': 'expectedUpdateCount'
    },
  ],
};

/// Descriptor for `NodeLabelsUpdateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeLabelsUpdateRequestDescriptor =
    $convert.base64Decode(
        'ChdOb2RlTGFiZWxzVXBkYXRlUmVxdWVzdBIWCgZsYWJlbHMYASADKAlSBmxhYmVscxIyChVleH'
        'BlY3RlZF91cGRhdGVfY291bnQYAiABKARSE2V4cGVjdGVkVXBkYXRlQ291bnQ=');

@$core.Deprecated('Use labelSearchQueryDescriptor instead')
const LabelSearchQuery$json = {
  '1': 'LabelSearchQuery',
  '2': [
    {'1': 'prefix', '3': 1, '4': 1, '5': 9, '10': 'prefix'},
    {'1': 'limit', '3': 2, '4': 1, '5': 13, '10': 'limit'},
  ],
};

/// Descriptor for `LabelSearchQuery`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List labelSearchQueryDescriptor = $convert.base64Decode(
    'ChBMYWJlbFNlYXJjaFF1ZXJ5EhYKBnByZWZpeBgBIAEoCVIGcHJlZml4EhQKBWxpbWl0GAIgAS'
    'gNUgVsaW1pdA==');

@$core.Deprecated('Use labelSummaryDescriptor instead')
const LabelSummary$json = {
  '1': 'LabelSummary',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'node_count', '3': 2, '4': 1, '5': 4, '10': 'nodeCount'},
  ],
};

/// Descriptor for `LabelSummary`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List labelSummaryDescriptor = $convert.base64Decode(
    'CgxMYWJlbFN1bW1hcnkSEgoEbmFtZRgBIAEoCVIEbmFtZRIdCgpub2RlX2NvdW50GAIgASgEUg'
    'lub2RlQ291bnQ=');

@$core.Deprecated('Use labelSearchResultDescriptor instead')
const LabelSearchResult$json = {
  '1': 'LabelSearchResult',
  '2': [
    {
      '1': 'labels',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.seville.nodes.v1.LabelSummary',
      '10': 'labels'
    },
  ],
};

/// Descriptor for `LabelSearchResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List labelSearchResultDescriptor = $convert.base64Decode(
    'ChFMYWJlbFNlYXJjaFJlc3VsdBI2CgZsYWJlbHMYASADKAsyHi5zZXZpbGxlLm5vZGVzLnYxLk'
    'xhYmVsU3VtbWFyeVIGbGFiZWxz');

@$core.Deprecated('Use labelRenameRequestDescriptor instead')
const LabelRenameRequest$json = {
  '1': 'LabelRenameRequest',
  '2': [
    {'1': 'new_name', '3': 1, '4': 1, '5': 9, '10': 'newName'},
  ],
};

/// Descriptor for `LabelRenameRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List labelRenameRequestDescriptor =
    $convert.base64Decode(
        'ChJMYWJlbFJlbmFtZVJlcXVlc3QSGQoIbmV3X25hbWUYASABKAlSB25ld05hbWU=');

@$core.Deprecated('Use labelMutationResultDescriptor instead')
const LabelMutationResult$json = {
  '1': 'LabelMutationResult',
  '2': [
    {
      '1': 'changed_node_count',
      '3': 1,
      '4': 1,
      '5': 4,
      '10': 'changedNodeCount'
    },
  ],
};

/// Descriptor for `LabelMutationResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List labelMutationResultDescriptor = $convert.base64Decode(
    'ChNMYWJlbE11dGF0aW9uUmVzdWx0EiwKEmNoYW5nZWRfbm9kZV9jb3VudBgBIAEoBFIQY2hhbm'
    'dlZE5vZGVDb3VudA==');
