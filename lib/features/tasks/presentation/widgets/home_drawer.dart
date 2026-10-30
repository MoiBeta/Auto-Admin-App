import 'package:auto_admin_app/core/constants/routes.dart';
import 'package:auto_admin_app/features/auth/injection/auth_providers.dart';
import 'package:auto_admin_app/features/tasks/presentation/provider/home_provider.dart';
import 'package:auto_admin_app/global/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeDrawer extends ConsumerStatefulWidget {
  const HomeDrawer({super.key});

  @override
  ConsumerState<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends ConsumerState<HomeDrawer> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return NavigationDrawer(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) async {
        setState(() => _selectedIndex = index);
        if (index == 1) {
          // Logout. Closing the drawer disposes this widget and its ref.
          final container = ProviderScope.containerOf(context, listen: false);
          Navigator.of(context).pop();
          // While the session is valid: save the pending subtask changes.
          await container.read(homeProvider.notifier).flushSubtaskSyncs();
          container.read(authNotifierProvider.notifier).logout();
          container.invalidate(homeProvider);
          container.read(routerProvider).go(Routes.auth);
        }
      },
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
          ),
          child: Text(
            'Auto Admin',
            style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Inicio'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.logout_outlined),
          selectedIcon: Icon(Icons.logout),
          label: Text('Cerrar sesión'),
        ),
      ],
    );
  }
}
