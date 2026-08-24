import 'package:auto_admin_app/core/constants/routes.dart';
import 'package:auto_admin_app/features/auth/injection/auth_providers.dart';
import 'package:auto_admin_app/global/theme/spacing.dart';
import 'package:auto_admin_app/global/widgets/loading_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class RegisterScreen extends HookConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fullNameController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();

    final loginState = ref.watch(authNotifierProvider).value;
    final isLoading = loginState?.isLoading ?? false;

    ref.listen(authNotifierProvider, (previous, next) {
      final credentials = next.value?.credentials;
      if (credentials != null && context.mounted) {
        context.go(Routes.home);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.formHorizontal),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: fullNameController,
              decoration: const InputDecoration(hintText: 'Nombre Completo'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: Spacing.formFieldSpacing),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'Correo'),
            ),
            const SizedBox(height: Spacing.formFieldSpacing),
            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Contraseña'),
            ),
            const SizedBox(height: Spacing.formFieldSpacing),
            LoadingButton(
              isLoading: isLoading,
              onPressed: () async {
                await ref.read(authNotifierProvider.notifier).register(
                      email: emailController.text,
                      password: passwordController.text,
                      fullName: fullNameController.text,
                    );
              },
              label: 'Registrarse',
            ),
            const SizedBox(height: Spacing.sm),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () => context.pushReplacementNamed(Routes.login),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}
