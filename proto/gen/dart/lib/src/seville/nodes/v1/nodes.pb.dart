// This is a generated file - do not edit.
//
// Generated from seville/nodes/v1/nodes.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import '../../node/v2/node.pb.dart' as $0;
import 'nodes.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'nodes.pbenum.dart';

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
    NodeSearchMatchMode? includeMatchMode,
    $core.bool? negated,
  }) {
    final result = create();
    if (includeNodesMatching != null)
      result.includeNodesMatching.addAll(includeNodesMatching);
    if (excludeNodesMatching != null)
      result.excludeNodesMatching.addAll(excludeNodesMatching);
    if (includeMatchMode != null) result.includeMatchMode = includeMatchMode;
    if (negated != null) result.negated = negated;
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
    ..aE<NodeSearchMatchMode>(3, _omitFieldNames ? '' : 'includeMatchMode',
        enumValues: NodeSearchMatchMode.values)
    ..aOB(4, _omitFieldNames ? '' : 'negated')
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

  @$pb.TagNumber(3)
  NodeSearchMatchMode get includeMatchMode => $_getN(2);
  @$pb.TagNumber(3)
  set includeMatchMode(NodeSearchMatchMode value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasIncludeMatchMode() => $_has(2);
  @$pb.TagNumber(3)
  void clearIncludeMatchMode() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get negated => $_getBF(3);
  @$pb.TagNumber(4)
  set negated($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNegated() => $_has(3);
  @$pb.TagNumber(4)
  void clearNegated() => $_clearField(4);
}

class NodeSearchQuery extends $pb.GeneratedMessage {
  factory NodeSearchQuery({
    NodeSearchFilter? nodeFilter,
    $core.int? limit,
  }) {
    final result = create();
    if (nodeFilter != null) result.nodeFilter = nodeFilter;
    if (limit != null) result.limit = limit;
    return result;
  }

  NodeSearchQuery._();

  factory NodeSearchQuery.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NodeSearchQuery.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeSearchQuery',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'seville.nodes.v1'),
      createEmptyInstance: create)
    ..aOM<NodeSearchFilter>(1, _omitFieldNames ? '' : 'nodeFilter',
        subBuilder: NodeSearchFilter.create)
    ..aI(2, _omitFieldNames ? '' : 'limit', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeSearchQuery clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeSearchQuery copyWith(void Function(NodeSearchQuery) updates) =>
      super.copyWith((message) => updates(message as NodeSearchQuery))
          as NodeSearchQuery;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeSearchQuery create() => NodeSearchQuery._();
  @$core.override
  NodeSearchQuery createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NodeSearchQuery getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NodeSearchQuery>(create);
  static NodeSearchQuery? _defaultInstance;

  @$pb.TagNumber(1)
  NodeSearchFilter get nodeFilter => $_getN(0);
  @$pb.TagNumber(1)
  set nodeFilter(NodeSearchFilter value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasNodeFilter() => $_has(0);
  @$pb.TagNumber(1)
  void clearNodeFilter() => $_clearField(1);
  @$pb.TagNumber(1)
  NodeSearchFilter ensureNodeFilter() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.int get limit => $_getIZ(1);
  @$pb.TagNumber(2)
  set limit($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearLimit() => $_clearField(2);
}

class NodeSearchResult extends $pb.GeneratedMessage {
  factory NodeSearchResult({
    $core.Iterable<$0.Node>? nodes,
  }) {
    final result = create();
    if (nodes != null) result.nodes.addAll(nodes);
    return result;
  }

  NodeSearchResult._();

  factory NodeSearchResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NodeSearchResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeSearchResult',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'seville.nodes.v1'),
      createEmptyInstance: create)
    ..pPM<$0.Node>(1, _omitFieldNames ? '' : 'nodes',
        subBuilder: $0.Node.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeSearchResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeSearchResult copyWith(void Function(NodeSearchResult) updates) =>
      super.copyWith((message) => updates(message as NodeSearchResult))
          as NodeSearchResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeSearchResult create() => NodeSearchResult._();
  @$core.override
  NodeSearchResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NodeSearchResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NodeSearchResult>(create);
  static NodeSearchResult? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$0.Node> get nodes => $_getList(0);
}

class NodeCreateRequest extends $pb.GeneratedMessage {
  factory NodeCreateRequest({
    $core.String? slug,
    $core.Iterable<$core.String>? labels,
    $core.String? body,
  }) {
    final result = create();
    if (slug != null) result.slug = slug;
    if (labels != null) result.labels.addAll(labels);
    if (body != null) result.body = body;
    return result;
  }

  NodeCreateRequest._();

  factory NodeCreateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NodeCreateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeCreateRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'seville.nodes.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'slug')
    ..pPS(2, _omitFieldNames ? '' : 'labels')
    ..aOS(3, _omitFieldNames ? '' : 'body')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeCreateRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeCreateRequest copyWith(void Function(NodeCreateRequest) updates) =>
      super.copyWith((message) => updates(message as NodeCreateRequest))
          as NodeCreateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeCreateRequest create() => NodeCreateRequest._();
  @$core.override
  NodeCreateRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NodeCreateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NodeCreateRequest>(create);
  static NodeCreateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get slug => $_getSZ(0);
  @$pb.TagNumber(1)
  set slug($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSlug() => $_has(0);
  @$pb.TagNumber(1)
  void clearSlug() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get labels => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get body => $_getSZ(2);
  @$pb.TagNumber(3)
  set body($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBody() => $_has(2);
  @$pb.TagNumber(3)
  void clearBody() => $_clearField(3);
}

/// A bounded view of the canonical Node connection graph.
class NodeGraphQuery extends $pb.GeneratedMessage {
  factory NodeGraphQuery({
    $core.String? rootNodeSlug,
    $core.int? depth,
    $core.int? limit,
    $core.String? search,
  }) {
    final result = create();
    if (rootNodeSlug != null) result.rootNodeSlug = rootNodeSlug;
    if (depth != null) result.depth = depth;
    if (limit != null) result.limit = limit;
    if (search != null) result.search = search;
    return result;
  }

  NodeGraphQuery._();

  factory NodeGraphQuery.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NodeGraphQuery.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeGraphQuery',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'seville.nodes.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'rootNodeSlug')
    ..aI(2, _omitFieldNames ? '' : 'depth', fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'limit', fieldType: $pb.PbFieldType.OU3)
    ..aOS(4, _omitFieldNames ? '' : 'search')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeGraphQuery clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeGraphQuery copyWith(void Function(NodeGraphQuery) updates) =>
      super.copyWith((message) => updates(message as NodeGraphQuery))
          as NodeGraphQuery;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeGraphQuery create() => NodeGraphQuery._();
  @$core.override
  NodeGraphQuery createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NodeGraphQuery getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NodeGraphQuery>(create);
  static NodeGraphQuery? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get rootNodeSlug => $_getSZ(0);
  @$pb.TagNumber(1)
  set rootNodeSlug($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRootNodeSlug() => $_has(0);
  @$pb.TagNumber(1)
  void clearRootNodeSlug() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get depth => $_getIZ(1);
  @$pb.TagNumber(2)
  set depth($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDepth() => $_has(1);
  @$pb.TagNumber(2)
  void clearDepth() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get limit => $_getIZ(2);
  @$pb.TagNumber(3)
  set limit($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimit() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get search => $_getSZ(3);
  @$pb.TagNumber(4)
  set search($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSearch() => $_has(3);
  @$pb.TagNumber(4)
  void clearSearch() => $_clearField(4);
}

class NodeGraph extends $pb.GeneratedMessage {
  factory NodeGraph({
    $core.Iterable<$0.Node>? nodes,
    $core.Iterable<$0.NodeConnection>? connections,
    $core.bool? hasMore,
  }) {
    final result = create();
    if (nodes != null) result.nodes.addAll(nodes);
    if (connections != null) result.connections.addAll(connections);
    if (hasMore != null) result.hasMore = hasMore;
    return result;
  }

  NodeGraph._();

  factory NodeGraph.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NodeGraph.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeGraph',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'seville.nodes.v1'),
      createEmptyInstance: create)
    ..pPM<$0.Node>(1, _omitFieldNames ? '' : 'nodes',
        subBuilder: $0.Node.create)
    ..pPM<$0.NodeConnection>(2, _omitFieldNames ? '' : 'connections',
        subBuilder: $0.NodeConnection.create)
    ..aOB(3, _omitFieldNames ? '' : 'hasMore')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeGraph clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeGraph copyWith(void Function(NodeGraph) updates) =>
      super.copyWith((message) => updates(message as NodeGraph)) as NodeGraph;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeGraph create() => NodeGraph._();
  @$core.override
  NodeGraph createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NodeGraph getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NodeGraph>(create);
  static NodeGraph? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$0.Node> get nodes => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<$0.NodeConnection> get connections => $_getList(1);

  @$pb.TagNumber(3)
  $core.bool get hasMore => $_getBF(2);
  @$pb.TagNumber(3)
  set hasMore($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHasMore() => $_has(2);
  @$pb.TagNumber(3)
  void clearHasMore() => $_clearField(3);
}

class NodeBodyUpdateRequest extends $pb.GeneratedMessage {
  factory NodeBodyUpdateRequest({
    $core.String? body,
    $fixnum.Int64? expectedUpdateCount,
  }) {
    final result = create();
    if (body != null) result.body = body;
    if (expectedUpdateCount != null)
      result.expectedUpdateCount = expectedUpdateCount;
    return result;
  }

  NodeBodyUpdateRequest._();

  factory NodeBodyUpdateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NodeBodyUpdateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeBodyUpdateRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'seville.nodes.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'body')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'expectedUpdateCount', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeBodyUpdateRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeBodyUpdateRequest copyWith(
          void Function(NodeBodyUpdateRequest) updates) =>
      super.copyWith((message) => updates(message as NodeBodyUpdateRequest))
          as NodeBodyUpdateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeBodyUpdateRequest create() => NodeBodyUpdateRequest._();
  @$core.override
  NodeBodyUpdateRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NodeBodyUpdateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NodeBodyUpdateRequest>(create);
  static NodeBodyUpdateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get body => $_getSZ(0);
  @$pb.TagNumber(1)
  set body($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBody() => $_has(0);
  @$pb.TagNumber(1)
  void clearBody() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get expectedUpdateCount => $_getI64(1);
  @$pb.TagNumber(2)
  set expectedUpdateCount($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasExpectedUpdateCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpectedUpdateCount() => $_clearField(2);
}

/// PUT replaces one Node's complete temporal span; an absent span clears it.
class NodeTemporalUpdateRequest extends $pb.GeneratedMessage {
  factory NodeTemporalUpdateRequest({
    $0.NodeTemporalSpan? span,
    $fixnum.Int64? expectedUpdateCount,
  }) {
    final result = create();
    if (span != null) result.span = span;
    if (expectedUpdateCount != null)
      result.expectedUpdateCount = expectedUpdateCount;
    return result;
  }

  NodeTemporalUpdateRequest._();

  factory NodeTemporalUpdateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NodeTemporalUpdateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeTemporalUpdateRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'seville.nodes.v1'),
      createEmptyInstance: create)
    ..aOM<$0.NodeTemporalSpan>(1, _omitFieldNames ? '' : 'span',
        subBuilder: $0.NodeTemporalSpan.create)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'expectedUpdateCount', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeTemporalUpdateRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeTemporalUpdateRequest copyWith(
          void Function(NodeTemporalUpdateRequest) updates) =>
      super.copyWith((message) => updates(message as NodeTemporalUpdateRequest))
          as NodeTemporalUpdateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeTemporalUpdateRequest create() => NodeTemporalUpdateRequest._();
  @$core.override
  NodeTemporalUpdateRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NodeTemporalUpdateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NodeTemporalUpdateRequest>(create);
  static NodeTemporalUpdateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $0.NodeTemporalSpan get span => $_getN(0);
  @$pb.TagNumber(1)
  set span($0.NodeTemporalSpan value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSpan() => $_has(0);
  @$pb.TagNumber(1)
  void clearSpan() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.NodeTemporalSpan ensureSpan() => $_ensure(0);

  @$pb.TagNumber(2)
  $fixnum.Int64 get expectedUpdateCount => $_getI64(1);
  @$pb.TagNumber(2)
  set expectedUpdateCount($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasExpectedUpdateCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpectedUpdateCount() => $_clearField(2);
}

/// PUT replaces one canonical Node's complete set of Neo4j labels.
class NodeLabelsUpdateRequest extends $pb.GeneratedMessage {
  factory NodeLabelsUpdateRequest({
    $core.Iterable<$core.String>? labels,
    $fixnum.Int64? expectedUpdateCount,
  }) {
    final result = create();
    if (labels != null) result.labels.addAll(labels);
    if (expectedUpdateCount != null)
      result.expectedUpdateCount = expectedUpdateCount;
    return result;
  }

  NodeLabelsUpdateRequest._();

  factory NodeLabelsUpdateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NodeLabelsUpdateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeLabelsUpdateRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'seville.nodes.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'labels')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'expectedUpdateCount', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeLabelsUpdateRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeLabelsUpdateRequest copyWith(
          void Function(NodeLabelsUpdateRequest) updates) =>
      super.copyWith((message) => updates(message as NodeLabelsUpdateRequest))
          as NodeLabelsUpdateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeLabelsUpdateRequest create() => NodeLabelsUpdateRequest._();
  @$core.override
  NodeLabelsUpdateRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NodeLabelsUpdateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NodeLabelsUpdateRequest>(create);
  static NodeLabelsUpdateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get labels => $_getList(0);

  @$pb.TagNumber(2)
  $fixnum.Int64 get expectedUpdateCount => $_getI64(1);
  @$pb.TagNumber(2)
  set expectedUpdateCount($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasExpectedUpdateCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpectedUpdateCount() => $_clearField(2);
}

class LabelSearchQuery extends $pb.GeneratedMessage {
  factory LabelSearchQuery({
    $core.String? prefix,
    $core.int? limit,
  }) {
    final result = create();
    if (prefix != null) result.prefix = prefix;
    if (limit != null) result.limit = limit;
    return result;
  }

  LabelSearchQuery._();

  factory LabelSearchQuery.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LabelSearchQuery.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LabelSearchQuery',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'seville.nodes.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'prefix')
    ..aI(2, _omitFieldNames ? '' : 'limit', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LabelSearchQuery clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LabelSearchQuery copyWith(void Function(LabelSearchQuery) updates) =>
      super.copyWith((message) => updates(message as LabelSearchQuery))
          as LabelSearchQuery;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LabelSearchQuery create() => LabelSearchQuery._();
  @$core.override
  LabelSearchQuery createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LabelSearchQuery getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LabelSearchQuery>(create);
  static LabelSearchQuery? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get prefix => $_getSZ(0);
  @$pb.TagNumber(1)
  set prefix($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPrefix() => $_has(0);
  @$pb.TagNumber(1)
  void clearPrefix() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get limit => $_getIZ(1);
  @$pb.TagNumber(2)
  set limit($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearLimit() => $_clearField(2);
}

class LabelSummary extends $pb.GeneratedMessage {
  factory LabelSummary({
    $core.String? name,
    $fixnum.Int64? nodeCount,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (nodeCount != null) result.nodeCount = nodeCount;
    return result;
  }

  LabelSummary._();

  factory LabelSummary.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LabelSummary.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LabelSummary',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'seville.nodes.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'nodeCount', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LabelSummary clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LabelSummary copyWith(void Function(LabelSummary) updates) =>
      super.copyWith((message) => updates(message as LabelSummary))
          as LabelSummary;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LabelSummary create() => LabelSummary._();
  @$core.override
  LabelSummary createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LabelSummary getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LabelSummary>(create);
  static LabelSummary? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get nodeCount => $_getI64(1);
  @$pb.TagNumber(2)
  set nodeCount($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNodeCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearNodeCount() => $_clearField(2);
}

class LabelSearchResult extends $pb.GeneratedMessage {
  factory LabelSearchResult({
    $core.Iterable<LabelSummary>? labels,
  }) {
    final result = create();
    if (labels != null) result.labels.addAll(labels);
    return result;
  }

  LabelSearchResult._();

  factory LabelSearchResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LabelSearchResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LabelSearchResult',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'seville.nodes.v1'),
      createEmptyInstance: create)
    ..pPM<LabelSummary>(1, _omitFieldNames ? '' : 'labels',
        subBuilder: LabelSummary.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LabelSearchResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LabelSearchResult copyWith(void Function(LabelSearchResult) updates) =>
      super.copyWith((message) => updates(message as LabelSearchResult))
          as LabelSearchResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LabelSearchResult create() => LabelSearchResult._();
  @$core.override
  LabelSearchResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LabelSearchResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LabelSearchResult>(create);
  static LabelSearchResult? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<LabelSummary> get labels => $_getList(0);
}

class LabelRenameRequest extends $pb.GeneratedMessage {
  factory LabelRenameRequest({
    $core.String? newName,
  }) {
    final result = create();
    if (newName != null) result.newName = newName;
    return result;
  }

  LabelRenameRequest._();

  factory LabelRenameRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LabelRenameRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LabelRenameRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'seville.nodes.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'newName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LabelRenameRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LabelRenameRequest copyWith(void Function(LabelRenameRequest) updates) =>
      super.copyWith((message) => updates(message as LabelRenameRequest))
          as LabelRenameRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LabelRenameRequest create() => LabelRenameRequest._();
  @$core.override
  LabelRenameRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LabelRenameRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LabelRenameRequest>(create);
  static LabelRenameRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get newName => $_getSZ(0);
  @$pb.TagNumber(1)
  set newName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNewName() => $_has(0);
  @$pb.TagNumber(1)
  void clearNewName() => $_clearField(1);
}

class LabelMutationResult extends $pb.GeneratedMessage {
  factory LabelMutationResult({
    $fixnum.Int64? changedNodeCount,
  }) {
    final result = create();
    if (changedNodeCount != null) result.changedNodeCount = changedNodeCount;
    return result;
  }

  LabelMutationResult._();

  factory LabelMutationResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LabelMutationResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LabelMutationResult',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'seville.nodes.v1'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'changedNodeCount', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LabelMutationResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LabelMutationResult copyWith(void Function(LabelMutationResult) updates) =>
      super.copyWith((message) => updates(message as LabelMutationResult))
          as LabelMutationResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LabelMutationResult create() => LabelMutationResult._();
  @$core.override
  LabelMutationResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LabelMutationResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LabelMutationResult>(create);
  static LabelMutationResult? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get changedNodeCount => $_getI64(0);
  @$pb.TagNumber(1)
  set changedNodeCount($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChangedNodeCount() => $_has(0);
  @$pb.TagNumber(1)
  void clearChangedNodeCount() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
