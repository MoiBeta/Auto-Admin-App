import 'package:auto_admin_app/features/auth/injection/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Signs in with Google, creating the account on first use.
class GoogleSignInButton extends ConsumerWidget {
  const GoogleSignInButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading =
        ref.watch(authNotifierProvider.select((s) => s.value?.isLoading)) ??
            false;

    // Colors from Google's sign-in branding guidelines.
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? const Color(0xFF131314) : Colors.white;
    final foreground = dark ? const Color(0xFFE3E3E3) : const Color(0xFF1F1F1F);
    final border = dark ? const Color(0xFF8E918F) : const Color(0xFF747775);

    return OutlinedButton.icon(
      onPressed: isLoading
          ? null
          : () => ref.read(authNotifierProvider.notifier).loginWithGoogle(),
      style: OutlinedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        side: BorderSide(color: border),
      ),
      icon: Image.asset(
        'assets/images/google_g.png',
        width: 20,
        height: 20,
        // Decorative: the label already says what the button does.
        excludeFromSemantics: true,
      ),
      label: const Text('Continuar con Google'),
    );
  }
}
