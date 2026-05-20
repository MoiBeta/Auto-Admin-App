import 'package:auto_admin_app/core/storage/token_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final Provider<FlutterSecureStorage> storageProvider =
    Provider<FlutterSecureStorage>((_) => FlutterSecureStorage());

final Provider<TokenManager> tokenManagerProvider =
    Provider<TokenManager>((ref) => TokenManager(ref.watch(storageProvider)));
