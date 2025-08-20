import 'package:auto_admin_app/features/tasks/data/models/task_template.dart';
import 'package:auto_admin_app/core/constants/routes.dart';
import 'package:auto_admin_app/features/auth/injection/auth_injection.dart';
import 'package:auto_admin_app/features/auth/presentation/pages/auth_page.dart';
import 'package:auto_admin_app/features/auth/presentation/pages/login_screen.dart';
import 'package:auto_admin_app/features/auth/presentation/pages/register_screen.dart';
import 'package:auto_admin_app/features/tasks/presentation/pages/adding_task_screen.dart';
import 'package:auto_admin_app/features/tasks/presentation/pages/home_page.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: Routes.home,
    routes: [
      GoRoute(
        path: Routes.home,
        name: Routes.home,
        builder: (context, state) => const HomePage(),
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
        path: Routes.addingTask,
        name: Routes.addingTask,
        builder: (context, state) => AddingTaskScreen(
          taskTemplate:
              state.extra != null ? state.extra as TaskTemplate? : null,
        ),
      ),
    ],
    redirect: (context, state) {
      String currentRoute = state.uri.toString();
      final isAuthenticated =
          ref.read(authNotifierProvider).credentials != null;
      if (!isAuthenticated &&
          currentRoute != Routes.login &&
          currentRoute != Routes.register) {
        return Routes.auth;
      }
      return null;
    },
  );
}
