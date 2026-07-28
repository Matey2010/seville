import 'package:dio/dio.dart';
import 'package:fixnum/fixnum.dart';
import 'package:seville_proto/seville_proto.dart'
    hide NodeSearchFilter, NodeSearchMatchMode, NodeSearchParameter;
import 'package:seville_proto/seville_proto.dart'
    as wire
    show
        NodeParameterType,
        NodeCreateRequest,
        NodeMutationRequest,
        NodeMutationResult,
        NodePropertyValue,
        NodeRelationshipType,
        NodeSearchFilter,
        NodeSearchMatchMode,
        NodeSearchMatchOperator,
        NodeSearchParameter,
        NodeSearchQuery,
        NodeTreeQuery;

import '../models/layout/layout.dart';
import 'runtime_config.dart';

class SevilleApi {
  SevilleApi({
    String baseUrl = const String.fromEnvironment(
      'SEVILLE_BASE_URL',
      defaultValue: 'http://127.0.0.1:8787',
    ),
    String? token,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: const Duration(seconds: 3),
           receiveTimeout: const Duration(seconds: 5),
           headers: {'Authorization': 'Bearer ${token ?? sevilleToken()}'},
           responseType: ResponseType.bytes,
         ),
       );

  final Dio _dio;

  Future<BackendSummary> summary() async {
    await _dio.get<List<int>>('/healthz');
    try {
      final response = await _dio.get<List<int>>('/v2/status');
      final bytes = response.data;
      if (bytes == null) {
        throw const FormatException('The backend returned an empty status.');
      }
      return BackendSummary(status: ImportStatus.fromBuffer(bytes));
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        return const BackendSummary();
      }
      rethrow;
    }
  }

  Future<SystemInfo> systemInfo() async {
    final response = await _dio.get<List<int>>('/system/v1/info');
    final bytes = response.data;
    if (bytes == null) {
      throw const FormatException(
        'The backend returned empty system information.',
      );
    }
    return SystemInfo.fromBuffer(bytes);
  }

  Future<NodeTree> nodeTree({
    String? rootNodeId,
    NodeSearchFilter? rootNodeFilter,
    int depth = 3,
    GraphTraverseType traverseBy = GraphTraverseType.partOf,
    NodeSearchFilter? nodeFilter,
  }) async {
    if (depth < 0) {
      throw ArgumentError.value(depth, 'depth', 'must be unsigned');
    }
    final queryParameters = {
      if (rootNodeId != null && rootNodeId.trim().isNotEmpty)
        'root_node_id': rootNodeId.trim(),
      'depth': depth,
      'traverse_by': traverseBy.queryValue,
    };
    final query = wire.NodeTreeQuery(
      rootNodeId: rootNodeId?.trim(),
      rootNodeFilter: rootNodeFilter == null
          ? null
          : _wireSearchFilter(rootNodeFilter),
      depth: depth,
      traverseBy: _wireTraverseType(traverseBy),
      nodeFilter: nodeFilter == null ? null : _wireSearchFilter(nodeFilter),
    );
    late final Response<List<int>> response;
    try {
      response = await _dio.request<List<int>>(
        '/api/v1/node/tree',
        queryParameters: queryParameters,
        data: query.writeToBuffer(),
        options: Options(
          method: 'QUERY',
          contentType: 'application/x-protobuf',
        ),
      );
    } on DioException catch (error) {
      if ((rootNodeFilter == null || rootNodeFilter.isEmpty) &&
          (nodeFilter == null || nodeFilter.isEmpty) &&
          const [404, 405, 501].contains(error.response?.statusCode)) {
        response = await _dio.get<List<int>>(
          '/api/v1/node/tree',
          queryParameters: queryParameters,
        );
      } else {
        rethrow;
      }
    }
    final bytes = response.data;
    if (bytes == null) {
      throw const FormatException('The backend returned an empty Node tree.');
    }
    return NodeTree.fromBuffer(bytes);
  }

  Future<NodeSearchResult> searchNodes(String value, {int limit = 12}) async {
    final normalizedValue = value.trim();
    if (normalizedValue.isEmpty) return NodeSearchResult();
    if (limit < 1 || limit > 100) {
      throw ArgumentError.value(limit, 'limit', 'must be between 1 and 100');
    }
    final pattern = '(?i).*${RegExp.escape(normalizedValue)}.*';
    final filter = NodeSearchFilter.anyOf([
      for (final parameter in const [
        NodeParameter.slug,
        NodeParameter.title,
        NodeParameter.tag,
        NodeParameter.label,
      ])
        NodeSearchParameter(
          parameter: parameter,
          value: pattern,
          operator: NodeMatchOperator.regularExpression,
        ),
    ]);
    return queryNodes(nodeFilter: filter, limit: limit);
  }

  Future<NodeSearchResult> queryNodes({
    required NodeSearchFilter nodeFilter,
    int limit = 12,
  }) async {
    if (nodeFilter.isEmpty) {
      throw ArgumentError.value(nodeFilter, 'nodeFilter', 'must not be empty');
    }
    if (limit < 1 || limit > 100) {
      throw ArgumentError.value(limit, 'limit', 'must be between 1 and 100');
    }
    final query = wire.NodeSearchQuery(
      nodeFilter: _wireSearchFilter(nodeFilter),
      limit: limit,
    );
    final response = await _dio.request<List<int>>(
      '/api/v1/node/search',
      data: query.writeToBuffer(),
      options: Options(method: 'QUERY', contentType: 'application/x-protobuf'),
    );
    final bytes = response.data;
    if (bytes == null) {
      throw const FormatException('The backend returned empty Node search.');
    }
    return NodeSearchResult.fromBuffer(bytes);
  }

  Future<int> mutateNodes({
    required NodeSearchFilter nodeFilter,
    Map<String, Object> setProperties = const {},
    Iterable<String> removeProperties = const [],
  }) async {
    if (nodeFilter.isEmpty) {
      throw ArgumentError.value(nodeFilter, 'nodeFilter', 'must not be empty');
    }
    final request = wire.NodeMutationRequest(
      nodeFilter: _wireSearchFilter(nodeFilter),
      setProperties: setProperties.entries.map(
        (entry) => MapEntry(entry.key, _wirePropertyValue(entry.value)),
      ),
      removeProperties: removeProperties,
    );
    final response = await _dio.request<List<int>>(
      '/api/v1/node/',
      data: request.writeToBuffer(),
      options: Options(method: 'PATCH', contentType: 'application/x-protobuf'),
    );
    final bytes = response.data;
    if (bytes == null) {
      throw const FormatException(
        'The backend returned empty Node mutation data.',
      );
    }
    return wire.NodeMutationResult.fromBuffer(bytes).mutatedNodeCount.toInt();
  }

  Future<Node> createNode({
    required String slug,
    Iterable<String> labels = const [],
  }) async {
    final normalizedSlug = slug.trim();
    if (normalizedSlug.isEmpty) {
      throw ArgumentError.value(slug, 'slug', 'must not be empty');
    }
    final request = wire.NodeCreateRequest(
      slug: normalizedSlug,
      labels: labels,
    );
    final response = await _dio.post<List<int>>(
      '/api/v1/node/',
      data: request.writeToBuffer(),
      options: Options(contentType: 'application/x-protobuf'),
    );
    final bytes = response.data;
    if (bytes == null) {
      throw const FormatException('The backend returned empty Node data.');
    }
    return Node.fromBuffer(bytes);
  }

  void close() => _dio.close();
}

wire.NodeRelationshipType _wireTraverseType(GraphTraverseType value) =>
    switch (value) {
      GraphTraverseType.partOf =>
        wire.NodeRelationshipType.NODE_RELATIONSHIP_TYPE_PART_OF,
      GraphTraverseType.family =>
        wire.NodeRelationshipType.NODE_RELATIONSHIP_TYPE_FAMILY,
    };

wire.NodeSearchFilter _wireSearchFilter(
  NodeSearchFilter value,
) => wire.NodeSearchFilter(
  includeNodesMatching: value.includeNodesMatching.map(_wireSearchParameter),
  excludeNodesMatching: value.excludeNodesMatching.map(_wireSearchParameter),
  includeMatchMode: switch (value.includeMatchMode) {
    NodeSearchMatchMode.any =>
      wire.NodeSearchMatchMode.NODE_SEARCH_MATCH_MODE_ANY,
    NodeSearchMatchMode.all =>
      wire.NodeSearchMatchMode.NODE_SEARCH_MATCH_MODE_ALL,
  },
  negated: value.isNegated,
);

wire.NodeSearchParameter _wireSearchParameter(NodeSearchParameter value) =>
    wire.NodeSearchParameter(
      parameter: switch (value.parameter) {
        NodeParameter.name => wire.NodeParameterType.NODE_PARAMETER_TYPE_NAME,
        NodeParameter.id => wire.NodeParameterType.NODE_PARAMETER_TYPE_ID,
        NodeParameter.path => wire.NodeParameterType.NODE_PARAMETER_TYPE_PATH,
        NodeParameter.title => wire.NodeParameterType.NODE_PARAMETER_TYPE_TITLE,
        NodeParameter.tag => wire.NodeParameterType.NODE_PARAMETER_TYPE_TAG,
        NodeParameter.label => wire.NodeParameterType.NODE_PARAMETER_TYPE_LABEL,
        NodeParameter.slug => wire.NodeParameterType.NODE_PARAMETER_TYPE_SLUG,
      },
      operator: switch (value.operator) {
        NodeMatchOperator.exact =>
          wire.NodeSearchMatchOperator.NODE_SEARCH_MATCH_OPERATOR_EXACT,
        NodeMatchOperator.startsWith =>
          wire.NodeSearchMatchOperator.NODE_SEARCH_MATCH_OPERATOR_STARTS_WITH,
        NodeMatchOperator.endsWith =>
          wire.NodeSearchMatchOperator.NODE_SEARCH_MATCH_OPERATOR_ENDS_WITH,
        NodeMatchOperator.contains =>
          wire.NodeSearchMatchOperator.NODE_SEARCH_MATCH_OPERATOR_CONTAINS,
        NodeMatchOperator.regularExpression =>
          wire
              .NodeSearchMatchOperator
              .NODE_SEARCH_MATCH_OPERATOR_REGULAR_EXPRESSION,
      },
      stringValue: value.value,
    );

wire.NodePropertyValue _wirePropertyValue(Object value) => switch (value) {
  String value => wire.NodePropertyValue(stringValue: value),
  int value => wire.NodePropertyValue(integerValue: Int64(value)),
  double value => wire.NodePropertyValue(doubleValue: value),
  bool value => wire.NodePropertyValue(booleanValue: value),
  _ => throw ArgumentError.value(
    value,
    'setProperties',
    'values must be String, int, double, or bool',
  ),
};

class BackendSummary {
  const BackendSummary({this.status});

  final ImportStatus? status;
}
