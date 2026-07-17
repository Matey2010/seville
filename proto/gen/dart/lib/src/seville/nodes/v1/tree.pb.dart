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

import '../../node/v2/node.pb.dart' as $0;
import 'tree.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'tree.pbenum.dart';

class NodeTreeOccurrence extends $pb.GeneratedMessage {
  factory NodeTreeOccurrence({
    $core.String? occurrenceId,
    $core.String? parentOccurrenceId,
    $core.int? depth,
    $0.Node? node,
  }) {
    final result = create();
    if (occurrenceId != null) result.occurrenceId = occurrenceId;
    if (parentOccurrenceId != null)
      result.parentOccurrenceId = parentOccurrenceId;
    if (depth != null) result.depth = depth;
    if (node != null) result.node = node;
    return result;
  }

  NodeTreeOccurrence._();

  factory NodeTreeOccurrence.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NodeTreeOccurrence.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeTreeOccurrence',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'seville.nodes.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'occurrenceId')
    ..aOS(2, _omitFieldNames ? '' : 'parentOccurrenceId')
    ..aI(3, _omitFieldNames ? '' : 'depth', fieldType: $pb.PbFieldType.OU3)
    ..aOM<$0.Node>(4, _omitFieldNames ? '' : 'node', subBuilder: $0.Node.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeTreeOccurrence clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeTreeOccurrence copyWith(void Function(NodeTreeOccurrence) updates) =>
      super.copyWith((message) => updates(message as NodeTreeOccurrence))
          as NodeTreeOccurrence;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeTreeOccurrence create() => NodeTreeOccurrence._();
  @$core.override
  NodeTreeOccurrence createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NodeTreeOccurrence getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NodeTreeOccurrence>(create);
  static NodeTreeOccurrence? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get occurrenceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set occurrenceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOccurrenceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearOccurrenceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get parentOccurrenceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set parentOccurrenceId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasParentOccurrenceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearParentOccurrenceId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get depth => $_getIZ(2);
  @$pb.TagNumber(3)
  set depth($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDepth() => $_has(2);
  @$pb.TagNumber(3)
  void clearDepth() => $_clearField(3);

  @$pb.TagNumber(4)
  $0.Node get node => $_getN(3);
  @$pb.TagNumber(4)
  set node($0.Node value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasNode() => $_has(3);
  @$pb.TagNumber(4)
  void clearNode() => $_clearField(4);
  @$pb.TagNumber(4)
  $0.Node ensureNode() => $_ensure(3);
}

class NodeTree extends $pb.GeneratedMessage {
  factory NodeTree({
    $core.String? rootNodeId,
    NodeRelationshipType? relationship,
    $core.int? depth,
    $core.Iterable<NodeTreeOccurrence>? occurrences,
  }) {
    final result = create();
    if (rootNodeId != null) result.rootNodeId = rootNodeId;
    if (relationship != null) result.relationship = relationship;
    if (depth != null) result.depth = depth;
    if (occurrences != null) result.occurrences.addAll(occurrences);
    return result;
  }

  NodeTree._();

  factory NodeTree.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NodeTree.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeTree',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'seville.nodes.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'rootNodeId')
    ..aE<NodeRelationshipType>(2, _omitFieldNames ? '' : 'relationship',
        enumValues: NodeRelationshipType.values)
    ..aI(3, _omitFieldNames ? '' : 'depth', fieldType: $pb.PbFieldType.OU3)
    ..pPM<NodeTreeOccurrence>(4, _omitFieldNames ? '' : 'occurrences',
        subBuilder: NodeTreeOccurrence.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeTree clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeTree copyWith(void Function(NodeTree) updates) =>
      super.copyWith((message) => updates(message as NodeTree)) as NodeTree;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeTree create() => NodeTree._();
  @$core.override
  NodeTree createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NodeTree getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NodeTree>(create);
  static NodeTree? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get rootNodeId => $_getSZ(0);
  @$pb.TagNumber(1)
  set rootNodeId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRootNodeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRootNodeId() => $_clearField(1);

  @$pb.TagNumber(2)
  NodeRelationshipType get relationship => $_getN(1);
  @$pb.TagNumber(2)
  set relationship(NodeRelationshipType value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasRelationship() => $_has(1);
  @$pb.TagNumber(2)
  void clearRelationship() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get depth => $_getIZ(2);
  @$pb.TagNumber(3)
  set depth($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDepth() => $_has(2);
  @$pb.TagNumber(3)
  void clearDepth() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<NodeTreeOccurrence> get occurrences => $_getList(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
