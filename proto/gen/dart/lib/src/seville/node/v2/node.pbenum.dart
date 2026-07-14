// This is a generated file - do not edit.
//
// Generated from seville/node/v2/node.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class NodeConnectionKind extends $pb.ProtobufEnum {
  static const NodeConnectionKind NODE_CONNECTION_KIND_UNSPECIFIED =
      NodeConnectionKind._(
          0, _omitEnumNames ? '' : 'NODE_CONNECTION_KIND_UNSPECIFIED');
  static const NodeConnectionKind NODE_CONNECTION_KIND_WIKI =
      NodeConnectionKind._(
          1, _omitEnumNames ? '' : 'NODE_CONNECTION_KIND_WIKI');
  static const NodeConnectionKind NODE_CONNECTION_KIND_MARKDOWN =
      NodeConnectionKind._(
          2, _omitEnumNames ? '' : 'NODE_CONNECTION_KIND_MARKDOWN');
  static const NodeConnectionKind NODE_CONNECTION_KIND_EMBED =
      NodeConnectionKind._(
          3, _omitEnumNames ? '' : 'NODE_CONNECTION_KIND_EMBED');

  static const $core.List<NodeConnectionKind> values = <NodeConnectionKind>[
    NODE_CONNECTION_KIND_UNSPECIFIED,
    NODE_CONNECTION_KIND_WIKI,
    NODE_CONNECTION_KIND_MARKDOWN,
    NODE_CONNECTION_KIND_EMBED,
  ];

  static final $core.List<NodeConnectionKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static NodeConnectionKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const NodeConnectionKind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
