import 'package:auto_admin_app/core/storage/token_manager.dart';
import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  final TokenManager tokenManager;
  final Dio refreshDio;

  AuthInterceptor(this.tokenManager, this.refreshDio);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await tokenManager.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await tokenManager.getRefreshToken();

      if (refreshToken != null) {
        try {
          final response = await refreshDio.post(
            '/auth/refresh',
            data: {'refreshToken': refreshToken},
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final newAccessToken = response.data['accessToken'];
            final newRefreshToken = response.data['refreshToken'];

            await tokenManager.saveTokens(
              accessToken: newAccessToken,
              refreshToken: newRefreshToken,
            );

            final requestOptions = err.requestOptions;
            requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

            final responseRetry = await refreshDio.request(
              requestOptions.path,
              options: Options(
                method: requestOptions.method,
                headers: requestOptions.headers,
              ),
              data: requestOptions.data,
              queryParameters: requestOptions.queryParameters,
            );

            return handler.resolve(responseRetry);
          }
        } catch (e) {
          await tokenManager.deleteTokens();
        }
      }
    }
    return super.onError(err, handler);
  }
}
