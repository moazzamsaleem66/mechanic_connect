import 'package:flutter/material.dart';

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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
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
                        Text('Welcome Back',
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Sign in to continue managing roadside requests.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppTextField(
                          controller: _emailController,
                          hintText: 'Email',
                          prefixIcon: const Icon(Icons.mail_outline),
                          textInputType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _passwordController,
                          hintText: 'Password',
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
                            child: const Text('Forgot password?'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppPrimaryButton(label: 'Login', onPressed: _onLogin),
                        const SizedBox(height: AppSpacing.sm),
                        AppSecondaryButton(
                            label: 'Continue as Guest', onPressed: _onLogin),
                        const SizedBox(height: AppSpacing.xl),
                        Center(
                          child: Text(
                            'or continue with',
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
