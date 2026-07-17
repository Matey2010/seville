// This is a generated file - do not edit.
//
// Generated from seville/nodes/v1/tree.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class NodeRelationshipType extends $pb.ProtobufEnum {
  static const NodeRelationshipType NODE_RELATIONSHIP_TYPE_UNSPECIFIED =
      NodeRelationshipType._(
          0, _omitEnumNames ? '' : 'NODE_RELATIONSHIP_TYPE_UNSPECIFIED');
  static const NodeRelationshipType NODE_RELATIONSHIP_TYPE_PART_OF =
      NodeRelationshipType._(
          1, _omitEnumNames ? '' : 'NODE_RELATIONSHIP_TYPE_PART_OF');

  static const $core.List<NodeRelationshipType> values = <NodeRelationshipType>[
    NODE_RELATIONSHIP_TYPE_UNSPECIFIED,
    NODE_RELATIONSHIP_TYPE_PART_OF,
  ];

  static final $core.List<NodeRelationshipType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static NodeRelationshipType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const NodeRelationshipType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
