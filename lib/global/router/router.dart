import 'package:auto_admin_app/core/constants/routes.dart';
import 'package:auto_admin_app/features/auth/injection/auth_injection.dart';
import 'package:auto_admin_app/features/auth/presentation/pages/auth_page.dart';
import 'package:auto_admin_app/features/auth/presentation/pages/login_screen.dart';
import 'package:auto_admin_app/features/auth/presentation/pages/register_screen.dart';
import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/presentation/pages/adding_task_screen.dart';
import 'package:auto_admin_app/features/tasks/presentation/pages/home_page.dart';
import 'package:auto_admin_app/global/pages/splash_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    routes: [
      GoRoute(
        path: Routes.splash,
        name: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.auth,
        name: Routes.auth,
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: Routes.login,
        name: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        name: Routes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.home,
        name: Routes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: Routes.addingTask,
        name: Routes.addingTask,
        builder: (context, state) => AddingTaskScreen(
          task: state.extra != null ? state.extra as Task? : null,
        ),
      ),
    ],
    redirect: (context, state) {
      final isAuthenticated =
          ref.read(authNotifierProvider).credentials != null;

      if (state.uri.toString() == Routes.splash) return null;

      final goingToAuth = state.uri.toString() == Routes.login ||
          state.uri.toString() == Routes.register ||
          state.uri.toString() == Routes.auth;

      if (!isAuthenticated && !goingToAuth) {
        return Routes.auth;
      }

      if (isAuthenticated && goingToAuth) {
        return Routes.home;
      }

      return null;
    },
  );
}
