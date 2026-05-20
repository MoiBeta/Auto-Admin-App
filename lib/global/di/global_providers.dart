import 'package:auto_admin_app/core/network/dio_client.dart';
import 'package:auto_admin_app/core/storage/token_manager.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/network/interceptors/auth_interceptor.dart';

final Provider<FlutterSecureStorage> storageProvider =
    Provider<FlutterSecureStorage>((_) => FlutterSecureStorage());

final Provider<TokenManager> tokenManagerProvider =
    Provider<TokenManager>((ref) => TokenManager(ref.watch(storageProvider)));
