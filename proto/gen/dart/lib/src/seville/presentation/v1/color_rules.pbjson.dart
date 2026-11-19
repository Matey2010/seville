// This is a generated file - do not edit.
//
// Generated from seville/presentation/v1/color_rules.proto.

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

@$core.Deprecated('Use colorRuleFieldDescriptor instead')
const ColorRuleField$json = {
  '1': 'ColorRuleField',
  '2': [
    {'1': 'COLOR_RULE_FIELD_UNSPECIFIED', '2': 0},
    {'1': 'COLOR_RULE_FIELD_LABEL', '2': 2},
    {'1': 'COLOR_RULE_FIELD_SLUG', '2': 4},
    {'1': 'COLOR_RULE_FIELD_TITLE', '2': 5},
    {'1': 'COLOR_RULE_FIELD_FRONTMATTER', '2': 6},
  ],
  '4': [
    {'1': 1, '2': 1},
    {'1': 3, '2': 3},
  ],
  '5': ['COLOR_RULE_FIELD_ID', 'COLOR_RULE_FIELD_TAG'],
};

/// Descriptor for `ColorRuleField`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List colorRuleFieldDescriptor = $convert.base64Decode(
    'Cg5Db2xvclJ1bGVGaWVsZBIgChxDT0xPUl9SVUxFX0ZJRUxEX1VOU1BFQ0lGSUVEEAASGgoWQ0'
    '9MT1JfUlVMRV9GSUVMRF9MQUJFTBACEhkKFUNPTE9SX1JVTEVfRklFTERfU0xVRxAEEhoKFkNP'
    'TE9SX1JVTEVfRklFTERfVElUTEUQBRIgChxDT0xPUl9SVUxFX0ZJRUxEX0ZST05UTUFUVEVSEA'
    'YiBAgBEAEiBAgDEAMqE0NPTE9SX1JVTEVfRklFTERfSUQqFENPTE9SX1JVTEVfRklFTERfVEFH');

@$core.Deprecated('Use colorRuleOperatorDescriptor instead')
const ColorRuleOperator$json = {
  '1': 'ColorRuleOperator',
  '2': [
    {'1': 'COLOR_RULE_OPERATOR_UNSPECIFIED', '2': 0},
    {'1': 'COLOR_RULE_OPERATOR_EXACT', '2': 1},
    {'1': 'COLOR_RULE_OPERATOR_CONTAINS', '2': 2},
    {'1': 'COLOR_RULE_OPERATOR_STARTS_WITH', '2': 3},
  ],
};

/// Descriptor for `ColorRuleOperator`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List colorRuleOperatorDescriptor = $convert.base64Decode(
    'ChFDb2xvclJ1bGVPcGVyYXRvchIjCh9DT0xPUl9SVUxFX09QRVJBVE9SX1VOU1BFQ0lGSUVEEA'
    'ASHQoZQ09MT1JfUlVMRV9PUEVSQVRPUl9FWEFDVBABEiAKHENPTE9SX1JVTEVfT1BFUkFUT1Jf'
    'Q09OVEFJTlMQAhIjCh9DT0xPUl9SVUxFX09QRVJBVE9SX1NUQVJUU19XSVRIEAM=');

@$core.Deprecated('Use nodeColorRuleDescriptor instead')
const NodeColorRule$json = {
  '1': 'NodeColorRule',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'enabled', '3': 2, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'weight', '3': 3, '4': 1, '5': 5, '10': 'weight'},
    {
      '1': 'field',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.seville.presentation.v1.ColorRuleField',
      '10': 'field'
    },
    {
      '1': 'operator',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.seville.presentation.v1.ColorRuleOperator',
      '10': 'operator'
    },
    {'1': 'value', '3': 6, '4': 1, '5': 9, '10': 'value'},
    {'1': 'frontmatter_key', '3': 7, '4': 1, '5': 9, '10': 'frontmatterKey'},
    {'1': 'color_hex', '3': 8, '4': 1, '5': 9, '10': 'colorHex'},
    {
      '1': 'gravity_scale',
      '3': 9,
      '4': 1,
      '5': 1,
      '9': 0,
      '10': 'gravityScale',
      '17': true
    },
    {
      '1': 'size_scale',
      '3': 10,
      '4': 1,
      '5': 1,
      '9': 1,
      '10': 'sizeScale',
      '17': true
    },
  ],
  '8': [
    {'1': '_gravity_scale'},
    {'1': '_size_scale'},
  ],
};

/// Descriptor for `NodeColorRule`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeColorRuleDescriptor = $convert.base64Decode(
    'Cg1Ob2RlQ29sb3JSdWxlEhIKBG5hbWUYASABKAlSBG5hbWUSGAoHZW5hYmxlZBgCIAEoCFIHZW'
    '5hYmxlZBIWCgZ3ZWlnaHQYAyABKAVSBndlaWdodBI9CgVmaWVsZBgEIAEoDjInLnNldmlsbGUu'
    'cHJlc2VudGF0aW9uLnYxLkNvbG9yUnVsZUZpZWxkUgVmaWVsZBJGCghvcGVyYXRvchgFIAEoDj'
    'IqLnNldmlsbGUucHJlc2VudGF0aW9uLnYxLkNvbG9yUnVsZU9wZXJhdG9yUghvcGVyYXRvchIU'
    'CgV2YWx1ZRgGIAEoCVIFdmFsdWUSJwoPZnJvbnRtYXR0ZXJfa2V5GAcgASgJUg5mcm9udG1hdH'
    'RlcktleRIbCgljb2xvcl9oZXgYCCABKAlSCGNvbG9ySGV4EigKDWdyYXZpdHlfc2NhbGUYCSAB'
    'KAFIAFIMZ3Jhdml0eVNjYWxliAEBEiIKCnNpemVfc2NhbGUYCiABKAFIAVIJc2l6ZVNjYWxliA'
    'EBQhAKDl9ncmF2aXR5X3NjYWxlQg0KC19zaXplX3NjYWxl');

@$core.Deprecated('Use nodeColorRuleSetDescriptor instead')
const NodeColorRuleSet$json = {
  '1': 'NodeColorRuleSet',
  '2': [
    {'1': 'revision', '3': 1, '4': 1, '5': 4, '10': 'revision'},
    {
      '1': 'rules',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.seville.presentation.v1.NodeColorRule',
      '10': 'rules'
    },
  ],
};

/// Descriptor for `NodeColorRuleSet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeColorRuleSetDescriptor = $convert.base64Decode(
    'ChBOb2RlQ29sb3JSdWxlU2V0EhoKCHJldmlzaW9uGAEgASgEUghyZXZpc2lvbhI8CgVydWxlcx'
    'gCIAMoCzImLnNldmlsbGUucHJlc2VudGF0aW9uLnYxLk5vZGVDb2xvclJ1bGVSBXJ1bGVz');
