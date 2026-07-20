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

enum NodeSearchParameter_Value { stringValue, notSet }

class NodeSearchParameter extends $pb.GeneratedMessage {
  factory NodeSearchParameter({
    NodeParameterType? parameter,
    NodeSearchMatchOperator? operator,
    $core.String? stringValue,
  }) {
    final result = create();
    if (parameter != null) result.parameter = parameter;
    if (operator != null) result.operator = operator;
    if (stringValue != null) result.stringValue = stringValue;
    return result;
  }

  NodeSearchParameter._();

  factory NodeSearchParameter.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NodeSearchParameter.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, NodeSearchParameter_Value>
      _NodeSearchParameter_ValueByTag = {
    3: NodeSearchParameter_Value.stringValue,
    0: NodeSearchParameter_Value.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeSearchParameter',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'seville.nodes.v1'),
      createEmptyInstance: create)
    ..oo(0, [3])
    ..aE<NodeParameterType>(1, _omitFieldNames ? '' : 'parameter',
        enumValues: NodeParameterType.values)
    ..aE<NodeSearchMatchOperator>(2, _omitFieldNames ? '' : 'operator',
        enumValues: NodeSearchMatchOperator.values)
    ..aOS(3, _omitFieldNames ? '' : 'stringValue')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeSearchParameter clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeSearchParameter copyWith(void Function(NodeSearchParameter) updates) =>
      super.copyWith((message) => updates(message as NodeSearchParameter))
          as NodeSearchParameter;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeSearchParameter create() => NodeSearchParameter._();
  @$core.override
  NodeSearchParameter createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NodeSearchParameter getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NodeSearchParameter>(create);
  static NodeSearchParameter? _defaultInstance;

  @$pb.TagNumber(3)
  NodeSearchParameter_Value whichValue() =>
      _NodeSearchParameter_ValueByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(3)
  void clearValue() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  NodeParameterType get parameter => $_getN(0);
  @$pb.TagNumber(1)
  set parameter(NodeParameterType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasParameter() => $_has(0);
  @$pb.TagNumber(1)
  void clearParameter() => $_clearField(1);

  @$pb.TagNumber(2)
  NodeSearchMatchOperator get operator => $_getN(1);
  @$pb.TagNumber(2)
  set operator(NodeSearchMatchOperator value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasOperator() => $_has(1);
  @$pb.TagNumber(2)
  void clearOperator() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get stringValue => $_getSZ(2);
  @$pb.TagNumber(3)
  set stringValue($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasStringValue() => $_has(2);
  @$pb.TagNumber(3)
  void clearStringValue() => $_clearField(3);
}

class NodeSearchFilter extends $pb.GeneratedMessage {
  factory NodeSearchFilter({
    $core.Iterable<NodeSearchParameter>? includeNodesMatching,
    $core.Iterable<NodeSearchParameter>? excludeNodesMatching,
  }) {
    final result = create();
    if (includeNodesMatching != null)
      result.includeNodesMatching.addAll(includeNodesMatching);
    if (excludeNodesMatching != null)
      result.excludeNodesMatching.addAll(excludeNodesMatching);
    return result;
  }

  NodeSearchFilter._();

  factory NodeSearchFilter.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NodeSearchFilter.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeSearchFilter',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'seville.nodes.v1'),
      createEmptyInstance: create)
    ..pPM<NodeSearchParameter>(1, _omitFieldNames ? '' : 'includeNodesMatching',
        subBuilder: NodeSearchParameter.create)
    ..pPM<NodeSearchParameter>(2, _omitFieldNames ? '' : 'excludeNodesMatching',
        subBuilder: NodeSearchParameter.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeSearchFilter clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeSearchFilter copyWith(void Function(NodeSearchFilter) updates) =>
      super.copyWith((message) => updates(message as NodeSearchFilter))
          as NodeSearchFilter;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeSearchFilter create() => NodeSearchFilter._();
  @$core.override
  NodeSearchFilter createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NodeSearchFilter getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NodeSearchFilter>(create);
  static NodeSearchFilter? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<NodeSearchParameter> get includeNodesMatching => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<NodeSearchParameter> get excludeNodesMatching => $_getList(1);
}

class NodeTreeQuery extends $pb.GeneratedMessage {
  factory NodeTreeQuery({
    $core.String? rootNodeId,
    $core.int? depth,
    NodeRelationshipType? traverseBy,
    NodeSearchFilter? nodeFilter,
  }) {
    final result = create();
    if (rootNodeId != null) result.rootNodeId = rootNodeId;
    if (depth != null) result.depth = depth;
    if (traverseBy != null) result.traverseBy = traverseBy;
    if (nodeFilter != null) result.nodeFilter = nodeFilter;
    return result;
  }

  NodeTreeQuery._();

  factory NodeTreeQuery.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NodeTreeQuery.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeTreeQuery',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'seville.nodes.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'rootNodeId')
    ..aI(2, _omitFieldNames ? '' : 'depth', fieldType: $pb.PbFieldType.OU3)
    ..aE<NodeRelationshipType>(3, _omitFieldNames ? '' : 'traverseBy',
        enumValues: NodeRelationshipType.values)
    ..aOM<NodeSearchFilter>(4, _omitFieldNames ? '' : 'nodeFilter',
        subBuilder: NodeSearchFilter.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeTreeQuery clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeTreeQuery copyWith(void Function(NodeTreeQuery) updates) =>
      super.copyWith((message) => updates(message as NodeTreeQuery))
          as NodeTreeQuery;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeTreeQuery create() => NodeTreeQuery._();
  @$core.override
  NodeTreeQuery createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NodeTreeQuery getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NodeTreeQuery>(create);
  static NodeTreeQuery? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get rootNodeId => $_getSZ(0);
  @$pb.TagNumber(1)
  set rootNodeId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRootNodeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRootNodeId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get depth => $_getIZ(1);
  @$pb.TagNumber(2)
  set depth($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDepth() => $_has(1);
  @$pb.TagNumber(2)
  void clearDepth() => $_clearField(2);

  @$pb.TagNumber(3)
  NodeRelationshipType get traverseBy => $_getN(2);
  @$pb.TagNumber(3)
  set traverseBy(NodeRelationshipType value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasTraverseBy() => $_has(2);
  @$pb.TagNumber(3)
  void clearTraverseBy() => $_clearField(3);

  @$pb.TagNumber(4)
  NodeSearchFilter get nodeFilter => $_getN(3);
  @$pb.TagNumber(4)
  set nodeFilter(NodeSearchFilter value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasNodeFilter() => $_has(3);
  @$pb.TagNumber(4)
  void clearNodeFilter() => $_clearField(4);
  @$pb.TagNumber(4)
  NodeSearchFilter ensureNodeFilter() => $_ensure(3);
}

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
