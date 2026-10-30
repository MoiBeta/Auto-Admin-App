import 'package:auto_admin_app/core/errors/app_error.dart';
import 'package:auto_admin_app/core/errors/app_exception.dart';
import 'package:auto_admin_app/features/auth/injection/auth_providers.dart';
import 'package:auto_admin_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto_admin_app/global/pages/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _OfflineAuthNotifier extends AuthNotifier {
  static int attempts = 0;

  @override
  Future<LoginState> build() async {
    attempts++;
    throw const AppException(
      AppError(message: 'Sin conexión', type: AppErrorType.network),
    );
  }
}

void main() {
  testWidgets('without network offers a retry instead of the login',
      (tester) async {
    _OfflineAuthNotifier.attempts = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_OfflineAuthNotifier.new)
        ],
        child: const MaterialApp(home: SplashScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Sin conexión'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump();
    expect(_OfflineAuthNotifier.attempts, 2);
  });
}
