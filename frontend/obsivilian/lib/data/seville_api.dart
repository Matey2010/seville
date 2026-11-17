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

  Future<NodeGraph> nodeGraph({
    String? rootNodeId,
    String search = '',
    int depth = 1,
    int limit = 150,
  }) async {
    if (depth < 0 || depth > 2 || limit < 1 || limit > 200) {
      throw ArgumentError('Graph depth must be 0–2 and limit 1–200.');
    }
    final request = NodeGraphQuery(
      rootNodeId: rootNodeId?.trim(),
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
            NodeParameterType.NODE_PARAMETER_TYPE_TAG,
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
    required String id,
    required String body,
    required int expectedUpdateCount,
  }) async {
    if (id.trim().isEmpty || expectedUpdateCount < 0) {
      throw ArgumentError('A stable Node id and update count are required.');
    }
    final request = NodeBodyUpdateRequest(
      body: body,
      expectedUpdateCount: Int64(expectedUpdateCount),
    );
    final response = await _dio.request<List<int>>(
      '/api/v1/node/${Uri.encodeComponent(id.trim())}',
      data: request.writeToBuffer(),
      options: Options(method: 'PATCH', contentType: 'application/x-protobuf'),
    );
    final bytes = response.data;
    if (bytes == null) {
      throw const FormatException('The backend returned empty Node data.');
    }
    return Node.fromBuffer(bytes);
  }

  void close() => _dio.close();
}
