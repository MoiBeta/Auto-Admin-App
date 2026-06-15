import 'package:auto_admin_app/core/storage/token_manager.dart';
import 'package:dio/dio.dart';

class RefreshInterceptor extends Interceptor {
  RefreshInterceptor(this.tokenManager);

  TokenManager tokenManager;

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await tokenManager.getRefreshToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
