import 'package:flutter/material.dart';

import '../data/auth_session_store.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../home/presentation/home_screen.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_surface_card.dart';
import '../../shared/widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const String routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.loginUsernameRequired),
        ),
      );
      return;
    }

    await AuthSessionStore.saveLoggedInUsername(username);

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
  }

  void _onContinueAsGuest() {
    Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth >= 900;
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 460 : 520),
                  child: AppSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.l10n.loginWelcomeBack,
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          context.l10n.loginSubtitle,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppTextField(
                          controller: _usernameController,
                          hintText: context.l10n.loginUsernameHint,
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          textInputType: TextInputType.text,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _passwordController,
                          hintText: context.l10n.loginPasswordHint,
                          prefixIcon: const Icon(Icons.lock_outline),
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: Text(context.l10n.loginForgotPassword),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppPrimaryButton(
                            label: context.l10n.loginButton,
                            onPressed: () => _onLogin()),
                        const SizedBox(height: AppSpacing.sm),
                        AppSecondaryButton(
                            label: context.l10n.loginContinueAsGuest,
                            onPressed: _onContinueAsGuest),
                        const SizedBox(height: AppSpacing.xl),
                        Center(
                          child: Text(
                            context.l10n.loginContinueWith,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _RoundSocialIcon(
                              icon: Icons.auto_awesome,
                              background: AppColors.primary,
                            ),
                            SizedBox(width: AppSpacing.md),
                            _RoundSocialIcon(
                              icon: Icons.change_history_outlined,
                              background: Color(0xFFA8561B),
                            ),
                            SizedBox(width: AppSpacing.md),
                            _RoundSocialIcon(
                              icon: Icons.local_offer_outlined,
                              background: Color(0xFF2E2400),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RoundSocialIcon extends StatelessWidget {
  const _RoundSocialIcon({
    required this.icon,
    required this.background,
  });

  final IconData icon;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}
