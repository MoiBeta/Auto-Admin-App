import 'package:auto_admin_app/core/network/dio_client.dart';
import 'package:auto_admin_app/core/storage/token_manager.dart';
import 'package:auto_admin_app/features/auth/data/models/auth_credential_model.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/change_password_data.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/login_data.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/sign_up_data.dart';
import 'package:dio/dio.dart';

import 'auth_data_source.dart';

class AuthRemoteDataSource extends AuthDataSource {
  final TokenManager tokenManager;
  final DioClient client;

  AuthRemoteDataSource({required this.tokenManager, required this.client});

  @override
  Future<bool> changePassword(ChangePasswordData changePasswordData) {
    // TODO: implement changePassword
    throw UnimplementedError();
  }

  @override
  Future<bool> confirmEmail() {
    // TODO: implement confirmEmail
    throw UnimplementedError();
  }

  @override
  Future<AuthCredentialModel?> getAuthState() async {
    try {
      final response = await client.get(
        '/auth/me',
      );
      return AuthCredentialModel.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<AuthCredentialModel?> login(LoginData loginData) async {
    try {
      final response = await client.post(
        '/auth/login',
        data: loginData.toJson(),
      );

      if (response.statusCode == 200) {
        final userData = response.data['user'];
        final tokenData = response.data['tokens'];

        await tokenManager.saveTokens(
          accessToken: tokenData['accessToken'],
          refreshToken: tokenData['refreshToken'],
        );

        return AuthCredentialModel.fromJson(userData);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Invalidates the refresh token on the server.
      await client.post('/auth/logout');
    } catch (_) {
      // Log out locally even if the server can't be reached.
    }
    await tokenManager.deleteTokens();
  }

  @override
  Future<AuthCredentialModel?> registerUser(SignUpData signUpData) async {
    Response<dynamic> response =
        await client.post('/auth/register', data: signUpData.toJson());
    if (response.statusCode == 201) {
      final userData = response.data['user'];
      final tokenData = response.data['tokens'];

      await tokenManager.saveTokens(
        accessToken: tokenData['accessToken'],
        refreshToken: tokenData['refreshToken'],
      );

      return AuthCredentialModel.fromJson(userData);
    }
    return null;
  }

  @override
  Future<void> resendConfirmationCode() async {}
}
