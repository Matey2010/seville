// This is a generated file - do not edit.
//
// Generated from seville/system/v1/system.proto.

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

@$core.Deprecated('Use systemInfoDescriptor instead')
const SystemInfo$json = {
  '1': 'SystemInfo',
  '2': [
    {'1': 'node_count', '3': 1, '4': 1, '5': 4, '10': 'nodeCount'},
    {
      '1': 'node_property_count',
      '3': 2,
      '4': 1,
      '5': 4,
      '10': 'nodePropertyCount'
    },
    {'1': 'neo4j_labels', '3': 3, '4': 3, '5': 9, '10': 'neo4jLabels'},
    {'1': 'go_version', '3': 4, '4': 1, '5': 9, '10': 'goVersion'},
    {'1': 'neo4j_version', '3': 5, '4': 1, '5': 9, '10': 'neo4jVersion'},
  ],
};

/// Descriptor for `SystemInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List systemInfoDescriptor = $convert.base64Decode(
    'CgpTeXN0ZW1JbmZvEh0KCm5vZGVfY291bnQYASABKARSCW5vZGVDb3VudBIuChNub2RlX3Byb3'
    'BlcnR5X2NvdW50GAIgASgEUhFub2RlUHJvcGVydHlDb3VudBIhCgxuZW80al9sYWJlbHMYAyAD'
    'KAlSC25lbzRqTGFiZWxzEh0KCmdvX3ZlcnNpb24YBCABKAlSCWdvVmVyc2lvbhIjCg1uZW80al'
    '92ZXJzaW9uGAUgASgJUgxuZW80alZlcnNpb24=');
