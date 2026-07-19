import 'package:dio/dio.dart';
import 'package:seville_proto/seville_proto.dart';

import '../models/graph_traverse_type.dart';
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

  Future<NodeSnapshot> snapshot() async {
    final response = await _dio.get<List<int>>('/v2/snapshot');
    final bytes = response.data;
    if (bytes == null) {
      throw const FormatException('The backend returned an empty snapshot.');
    }
    return NodeSnapshot.fromBuffer(bytes);
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
    int depth = 3,
    GraphTraverseType traverseBy = GraphTraverseType.partOf,
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
    late final Response<List<int>> response;
    try {
      response = await _dio.request<List<int>>(
        '/nodes/v1/tree',
        queryParameters: queryParameters,
        options: Options(method: 'QUERY'),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode case 404 || 405 || 501) {
        response = await _dio.get<List<int>>(
          '/nodes/v1/tree',
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

  void close() => _dio.close();
}

class BackendSummary {
  const BackendSummary({this.status});

  final ImportStatus? status;
}
