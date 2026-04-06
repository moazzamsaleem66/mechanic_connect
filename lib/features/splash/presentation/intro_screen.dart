import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_locale.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../auth/presentation/login_screen.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  static const String routeName = '/intro';

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF00174D), Color(0xFF0A2A78)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.introWelcome,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.0,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.l10n.introWelcomeSupporting,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColors.surfaceAlt
                                    .withValues(alpha: 0.82),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const _LanguageToggle(),
                    ],
                  ),
                  const Spacer(flex: 2),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FractionallySizedBox(
                        widthFactor: 0.7,
                        child: Image.asset(
                          'assets/intro_logo_symbol_white.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            context.l10n.introHeading,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 3),
                  SizedBox(
                    width: double.infinity,
                    height: 62,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color(0xFF5F80B2)
                                        .withValues(alpha: 0.46),
                                    const Color(0xFF4E6EA3)
                                        .withValues(alpha: 0.34),
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.26),
                                  width: 1.15,
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const SizedBox.expand(),
                            ),
                            Positioned(
                              left: 16,
                              right: 16,
                              top: 1,
                              child: Container(
                                height: 1.2,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.34),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: ElevatedButton(
                                onPressed: () => _goToLogin(context),
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  surfaceTintColor: Colors.transparent,
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      context.l10n.introGetStarted,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _goToLogin(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle();

  @override
  Widget build(BuildContext context) {
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';
    final label =
        isUrdu ? context.l10n.switchToEnglish : context.l10n.switchToUrdu;
    final targetLocale = isUrdu ? const Locale('en') : const Locale('ur');

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => AppLocale.setLocale(targetLocale),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF5272A5).withValues(alpha: 0.34),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.public_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
