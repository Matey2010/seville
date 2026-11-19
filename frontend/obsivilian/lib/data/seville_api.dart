import 'package:dio/dio.dart';
import 'package:fixnum/fixnum.dart';
import 'package:seville_proto/seville_proto.dart';

import 'runtime_config.dart';

/// The existing Go API is the only source of canonical Nodes.
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

  Future<NodeColorRuleSet> nodeColorRules() async {
    final response = await _dio.get<List<int>>('/api/v1/graph/color-rules');
    final bytes = response.data;
    if (bytes == null) {
      throw const FormatException('The backend returned empty color rules.');
    }
    return NodeColorRuleSet.fromBuffer(bytes);
  }

  Future<NodeColorRuleSet> replaceNodeColorRules(NodeColorRuleSet rules) async {
    final response = await _dio.put<List<int>>(
      '/api/v1/graph/color-rules',
      data: rules.writeToBuffer(),
      options: Options(contentType: 'application/x-protobuf'),
    );
    final bytes = response.data;
    if (bytes == null) {
      throw const FormatException('The backend returned empty color rules.');
    }
    return NodeColorRuleSet.fromBuffer(bytes);
  }

  Future<NodeGraph> nodeGraph({
    String? rootNodeSlug,
    String search = '',
    int depth = 1,
    int limit = 200,
  }) async {
    if (depth < 0 || depth > 2 || limit < 1 || limit > 200) {
      throw ArgumentError('Graph depth must be 0–2 and limit 1–200.');
    }
    final request = NodeGraphQuery(
      rootNodeSlug: rootNodeSlug?.trim(),
      depth: depth,
      limit: limit,
      search: search.trim(),
    );
    final response = await _dio.request<List<int>>(
      '/api/v1/node/graph',
      data: request.writeToBuffer(),
      options: Options(method: 'QUERY', contentType: 'application/x-protobuf'),
    );
    final bytes = response.data;
    if (bytes == null) {
      throw const FormatException('The backend returned an empty Node graph.');
    }
    return NodeGraph.fromBuffer(bytes);
  }

  Future<NodeSearchResult> searchNodes(String value, {int limit = 12}) async {
    final search = value.trim();
    if (search.isEmpty) return NodeSearchResult();
    if (limit < 1 || limit > 100) {
      throw ArgumentError.value(limit, 'limit', 'must be between 1 and 100');
    }
    final pattern = '(?i).*${RegExp.escape(search)}.*';
    final request = NodeSearchQuery(
      nodeFilter: NodeSearchFilter(
        includeMatchMode: NodeSearchMatchMode.NODE_SEARCH_MATCH_MODE_ANY,
        includeNodesMatching: [
          for (final parameter in [
            NodeParameterType.NODE_PARAMETER_TYPE_SLUG,
            NodeParameterType.NODE_PARAMETER_TYPE_TITLE,
            NodeParameterType.NODE_PARAMETER_TYPE_LABEL,
          ])
            NodeSearchParameter(
              parameter: parameter,
              operator: NodeSearchMatchOperator
                  .NODE_SEARCH_MATCH_OPERATOR_REGULAR_EXPRESSION,
              stringValue: pattern,
            ),
        ],
      ),
      limit: limit,
    );
    final response = await _dio.request<List<int>>(
      '/api/v1/node/search',
      data: request.writeToBuffer(),
      options: Options(method: 'QUERY', contentType: 'application/x-protobuf'),
    );
    final bytes = response.data;
    if (bytes == null) {
      throw const FormatException('The backend returned empty Node search.');
    }
    return NodeSearchResult.fromBuffer(bytes);
  }

  Future<NodeSearchResult> nodesByExactSlugs(Iterable<String> values) async {
    final slugs = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    if (slugs.isEmpty) return NodeSearchResult();
    if (slugs.length > 100) {
      throw ArgumentError.value(slugs.length, 'values', 'at most 100 slugs');
    }
    final request = NodeSearchQuery(
      nodeFilter: NodeSearchFilter(
        includeMatchMode: NodeSearchMatchMode.NODE_SEARCH_MATCH_MODE_ANY,
        includeNodesMatching: [
          for (final slug in slugs)
            NodeSearchParameter(
              parameter: NodeParameterType.NODE_PARAMETER_TYPE_SLUG,
              operator:
                  NodeSearchMatchOperator.NODE_SEARCH_MATCH_OPERATOR_EXACT,
              stringValue: slug,
            ),
        ],
      ),
      limit: slugs.length,
    );
    final response = await _dio.request<List<int>>(
      '/api/v1/node/search',
      data: request.writeToBuffer(),
      options: Options(method: 'QUERY', contentType: 'application/x-protobuf'),
    );
    final bytes = response.data;
    if (bytes == null) {
      throw const FormatException('The backend returned empty Node search.');
    }
    return NodeSearchResult.fromBuffer(bytes);
  }

  Future<Node> createNode({
    required String slug,
    Iterable<String> labels = const [],
    String body = '',
  }) async {
    final normalizedSlug = slug.trim();
    if (normalizedSlug.isEmpty) {
      throw ArgumentError.value(slug, 'slug', 'must not be empty');
    }
    final request = NodeCreateRequest(
      slug: normalizedSlug,
      labels: labels,
      body: body,
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

  Future<Node> updateNodeBody({
    required String slug,
    required String body,
    required int expectedUpdateCount,
  }) async {
    if (slug.trim().isEmpty || expectedUpdateCount < 0) {
      throw ArgumentError('A Node slug and update count are required.');
    }
    final request = NodeBodyUpdateRequest(
      body: body,
      expectedUpdateCount: Int64(expectedUpdateCount),
    );
    final response = await _dio.request<List<int>>(
      '/api/v1/node/${Uri.encodeComponent(slug.trim())}',
      data: request.writeToBuffer(),
      options: Options(method: 'PATCH', contentType: 'application/x-protobuf'),
    );
    final bytes = response.data;
    if (bytes == null) {
      throw const FormatException('The backend returned empty Node data.');
    }
    return Node.fromBuffer(bytes);
  }

  Future<Node> replaceNodeTemporalSpan({
    required String slug,
    required NodeTemporalSpan? span,
    required int expectedUpdateCount,
  }) async {
    if (slug.trim().isEmpty || expectedUpdateCount < 0) {
      throw ArgumentError('A Node slug and update count are required.');
    }
    final request = NodeTemporalUpdateRequest(
      expectedUpdateCount: Int64(expectedUpdateCount),
    );
    if (span != null) request.span = span;
    final response = await _dio.put<List<int>>(
      '/api/v1/node/${Uri.encodeComponent(slug.trim())}/temporal',
      data: request.writeToBuffer(),
      options: Options(contentType: 'application/x-protobuf'),
    );
    final bytes = response.data;
    if (bytes == null) {
      throw const FormatException('The backend returned empty Node data.');
    }
    return Node.fromBuffer(bytes);
  }

  Future<LabelSearchResult> searchLabels({String prefix = ''}) async {
    final response = await _dio.request<List<int>>(
      '/api/v1/label/search',
      data: LabelSearchQuery(prefix: prefix, limit: 200).writeToBuffer(),
      options: Options(method: 'QUERY', contentType: 'application/x-protobuf'),
    );
    final bytes = response.data;
    if (bytes == null) {
      throw const FormatException('The backend returned empty labels.');
    }
    return LabelSearchResult.fromBuffer(bytes);
  }

  Future<Node> replaceNodeLabels({
    required String slug,
    required Iterable<String> labels,
    required int expectedUpdateCount,
  }) async {
    if (slug.trim().isEmpty || expectedUpdateCount < 0) {
      throw ArgumentError('A Node slug and update count are required.');
    }
    final request = NodeLabelsUpdateRequest(
      labels: labels,
      expectedUpdateCount: Int64(expectedUpdateCount),
    );
    final response = await _dio.put<List<int>>(
      '/api/v1/node/${Uri.encodeComponent(slug.trim())}/labels',
      data: request.writeToBuffer(),
      options: Options(contentType: 'application/x-protobuf'),
    );
    final bytes = response.data;
    if (bytes == null) {
      throw const FormatException('The backend returned empty Node data.');
    }
    return Node.fromBuffer(bytes);
  }

  Future<LabelMutationResult> renameLabel(String name, String newName) async {
    final response = await _dio.request<List<int>>(
      '/api/v1/label/${Uri.encodeComponent(name)}',
      data: LabelRenameRequest(newName: newName).writeToBuffer(),
      options: Options(method: 'PATCH', contentType: 'application/x-protobuf'),
    );
    final bytes = response.data;
    if (bytes == null) {
      throw const FormatException('The backend returned empty label data.');
    }
    return LabelMutationResult.fromBuffer(bytes);
  }

  Future<LabelMutationResult> deleteLabel(String name) async {
    final response = await _dio.delete<List<int>>(
      '/api/v1/label/${Uri.encodeComponent(name)}',
    );
    final bytes = response.data;
    if (bytes == null) {
      throw const FormatException('The backend returned empty label data.');
    }
    return LabelMutationResult.fromBuffer(bytes);
  }

  void close() => _dio.close();
}
