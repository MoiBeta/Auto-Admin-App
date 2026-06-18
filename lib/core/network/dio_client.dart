import 'package:dio/dio.dart';

class DioClient {
  final Dio dio;

  DioClient(this.dio);

  Future<Response> get(String path, {Map<String, dynamic>? query}) {
    return dio.get(path, queryParameters: query);
  }

  Future<Response> post(String path, {dynamic data}) {
    return dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return dio.put(path, data: data);
  }

  Future<Response> delete(String path) {
    return dio.delete(path);
  }

  Future<Response> patch(String path, {dynamic data}) {
    return dio.patch(path, data: data);
  }
}
