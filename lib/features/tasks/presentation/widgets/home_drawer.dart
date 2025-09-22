import 'package:auto_admin_app/core/constants/routes.dart';
import 'package:auto_admin_app/features/auth/injection/auth_injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeDrawer extends ConsumerWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 5,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    Text('Cerrar sesión'),
                  ],
                ),
                onTap: () async {
                  await ref.read(authNotifierProvider.notifier).logout();
                  if (context.mounted) {
                    context.pushReplacementNamed(Routes.auth);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
