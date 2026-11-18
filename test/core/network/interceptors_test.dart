import 'package:auto_admin_app/core/errors/error_handler.dart';
import 'package:auto_admin_app/core/network/interceptors/auth_interceptor.dart';
import 'package:auto_admin_app/core/network/interceptors/error_interceptor.dart';
import 'package:auto_admin_app/core/storage/token_manager.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers every request with [status].
class _FixedResponse extends Interceptor {
  final int status;

  _FixedResponse(this.status);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: status),
        type: DioExceptionType.badResponse,
      ),
      true,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({'refresh_token': 'token'});

  Future<String> errorMessageOf(String path) async {
    var sessionExpired = false;
    final tokens = TokenManager(const FlutterSecureStorage());
    final dio = Dio(BaseOptions(baseUrl: 'http://test'));
    final refreshDio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..interceptors.add(_FixedResponse(401));
    dio.interceptors.addAll([
      AuthInterceptor(
        tokenManager: tokens,
        requestDio: dio,
        refreshDio: refreshDio,
        onSessionExpired: () => sessionExpired = true,
      ),
      ErrorInterceptor(),
      _FixedResponse(401),
    ]);

    try {
      await dio.post(path);
      fail('The request should fail');
    } catch (e) {
      expect(sessionExpired, !path.startsWith('/auth/'));
      return ErrorHandler.extractAppError(e).message;
    }
  }

  test('wrong credentials neither refresh nor report an expired session',
      () async {
    expect(
      await errorMessageOf('/auth/login'),
      'Correo o contraseña incorrectos.',
    );
  });

  test('a rejected Google token neither refreshes nor expires the session',
      () async {
    expect(
      await errorMessageOf('/auth/google'),
      'No se pudo verificar tu cuenta de Google.',
    );
  });
}
