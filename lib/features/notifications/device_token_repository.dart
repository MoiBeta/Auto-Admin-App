import 'package:auto_admin_app/core/network/dio_client.dart';

class DeviceTokenRepository {
  final DioClient _client;

  DeviceTokenRepository(this._client);

  Future<void> registerToken({
    required String token,
    required String platform,
  }) async {
    await _client.post(
      '/devices/token',
      data: {'token': token, 'platform': platform},
    );
  }
}
