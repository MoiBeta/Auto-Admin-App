import 'package:auto_admin_app/core/constants/routes.dart';
import 'package:auto_admin_app/core/errors/global_message_notifier.dart';
import 'package:auto_admin_app/features/notifications/notification_providers.dart';
import 'package:auto_admin_app/features/notifications/push_notification_service.dart';
import 'package:auto_admin_app/features/tasks/presentation/provider/home_provider.dart';
import 'package:auto_admin_app/firebase_options.dart';
import 'package:auto_admin_app/global/router/router.dart';
import 'package:auto_admin_app/global/theme/app_theme.dart';
import 'package:auto_admin_app/global/widgets/forge/forge_fire_shader.dart';
import 'package:auto_admin_app/global/widgets/error_listener.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ready before the first task is completed; it never throws.
  ForgeFireShader.load();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await dotenv.load();

  final container = ProviderContainer();
  // The permission is requested when the user sets their first reminder.
  final pushService = container.read(pushNotificationServiceProvider);
  pushService.setupForegroundHandler(
    container.read(globalMessageProvider.notifier).show,
  );
  pushService.setupOpenedHandler(() {
    final now = DateTime.now();
    container
        .read(selectedDateProvider.notifier)
        .selectDate(DateTime(now.year, now.month, now.day));
    container.read(routerProvider).go(Routes.home);
  });
  PushNotificationService.setupBackgroundHandler();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      locale: const Locale('es'),
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      routerDelegate: router.routerDelegate,
      routeInformationParser: router.routeInformationParser,
      routeInformationProvider: router.routeInformationProvider,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      builder: (context, child) => ErrorListener(child: child!),
    );
  }
}
