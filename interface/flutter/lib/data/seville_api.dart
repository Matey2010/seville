import 'package:dio/dio.dart';
import 'package:seville_proto/seville_proto.dart';

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
      final response = await _dio.get<List<int>>('/v1/status');
      final bytes = response.data;
      if (bytes == null) {
        throw const FormatException('The backend returned an empty status.');
      }
      return BackendSummary(status: ScanStatus.fromBuffer(bytes));
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        return const BackendSummary();
      }
      rethrow;
    }
  }

  Future<KnowledgeSnapshot> snapshot() async {
    final response = await _dio.get<List<int>>('/v1/snapshot');
    final bytes = response.data;
    if (bytes == null) {
      throw const FormatException('The backend returned an empty snapshot.');
    }
    return KnowledgeSnapshot.fromBuffer(bytes);
  }

  void close() => _dio.close();
}

class BackendSummary {
  const BackendSummary({this.status});

  final ScanStatus? status;
}
