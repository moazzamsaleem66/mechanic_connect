import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../home/presentation/home_screen.dart';
import '../data/auth_session_store.dart';

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

  Future<void> _onLogin() async {
    final username = _emailController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.loginUsernameRequired)),
      );
      return;
    }

    await AuthSessionStore.saveLoggedInUsername(username);

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.loginFeatureSoon)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.neutral,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.neutral,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.neutral,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 58,
                          height: 58,
                          child: Image.asset(
                            'assets/in_app_icon.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(
                          height: 58,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              context.l10n.loginBrand,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Text(
                              context.l10n.loginHelp,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4E545F),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.help_outline_rounded,
                              color: Color(0xFF4E545F),
                              size: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      context.l10n.loginWelcomeBack,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF20232A),
                        height: 0.98,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.loginSubtitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF666C76),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _CredentialCard(
                      emailController: _emailController,
                      passwordController: _passwordController,
                      obscurePassword: _obscurePassword,
                      onToggleVisibility: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showComingSoon,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          textStyle: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Text(context.l10n.loginForgotPassword),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 62,
                      child: ElevatedButton(
                        onPressed: _onLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              context.l10n.loginButton,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.arrow_forward_rounded, size: 28),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 34),
                    Row(
                      children: [
                        const Expanded(
                          child:
                              Divider(color: Color(0xFFD8DCE3), thickness: 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            context.l10n.loginSecureAccess,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFC2C7CF),
                              letterSpacing: 1.7,
                            ),
                          ),
                        ),
                        const Expanded(
                          child:
                              Divider(color: Color(0xFFD8DCE3), thickness: 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: GestureDetector(
                        onTap: _showComingSoon,
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          children: [
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: Image.asset(
                                'assets/fingerprint_round.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.fingerprint,
                                  color: AppColors.primary,
                                  size: 30,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              context.l10n.loginBiometric,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4B515D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 52),
                    Center(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Text(
                            context.l10n.loginNoAccount,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF565D68),
                            ),
                          ),
                          GestureDetector(
                            onTap: _showComingSoon,
                            child: Text(
                              context.l10n.loginSignUp,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CredentialCard extends StatelessWidget {
  const _CredentialCard({
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onToggleVisibility,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E6EB)),
      ),
      child: Column(
        children: [
          _InputRow(
            controller: emailController,
            icon: Icons.alternate_email_rounded,
            hintText: context.l10n.loginEmailHint,
            keyboardType: TextInputType.emailAddress,
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE3E6EB)),
          _InputRow(
            controller: passwordController,
            icon: Icons.lock,
            hintText: context.l10n.loginPasswordHint,
            obscureText: obscurePassword,
            suffix: IconButton(
              onPressed: onToggleVisibility,
              splashRadius: 18,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: Icon(
                obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: const Color(0xFF8B909A),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  const _InputRow({
    required this.controller,
    required this.icon,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffix,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hintText;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(icon, color: const Color(0xFF8A8F99), size: 21),
                        const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3B4048),
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8B909A),
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (suffix != null) suffix!,
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}
