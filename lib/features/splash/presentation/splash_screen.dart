import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_colors.dart';
import '../../auth/data/auth_session_store.dart';
import '../../home/presentation/home_screen.dart';
import '../../../l10n/l10n.dart';
import 'intro_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String routeName = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goToNextScreen();
  }

  Future<void> _goToNextScreen() async {
    await Future<void>.delayed(const Duration(seconds: 5));
    if (!mounted) return;

    final loggedInUsername = await AuthSessionStore.getLoggedInUsername();
    if (!mounted) return;

    final nextRoute =
        loggedInUsername == null ? IntroScreen.routeName : HomeScreen.routeName;

    Navigator.of(context).pushReplacementNamed(nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    return const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF00174D),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: _SplashContent(),
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const Spacer(flex: 7),
                Image.asset(
                  'assets/brand_icon.png',
                  width: 142,
                  height: 142,
                ),
                Text(
                  context.l10n.splashTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.0,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  context.l10n.splashTagline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.surfaceAlt,
                    letterSpacing: 4,
                    height: 1.0,
                  ),
                ),
                const Spacer(flex: 8),
                const _SplashDots(),
                const SizedBox(height: 24),
                Text(
                  context.l10n.splashPoweredBy,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:  AppColors.surfaceAlt,
                    letterSpacing: 3,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                const _PoweredByBrand(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashDots extends StatelessWidget {
  const _SplashDots();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Dot(color: Color(0xFFF28C3B)),
        SizedBox(width: 7),
        _Dot(color: Color(0xFFDB7A33)),
        SizedBox(width: 7),
        _Dot(color: Color(0xFF5C74AF)),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _PoweredByBrand extends StatelessWidget {
  const _PoweredByBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.verified_user_rounded,
          size: 16,
          color: Color(0xFFF28C3B),
        ),
        const SizedBox(width: 8),
        Text(
          context.l10n.splashPoweredByBrand,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.0,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}
