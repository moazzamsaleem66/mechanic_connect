import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../auth/presentation/login_screen.dart';

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
    _goToLogin();
  }

  Future<void> _goToLogin() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.home_repair_service_rounded,
                  color: AppColors.onPrimary,
                  size: 44,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Mechanic Connect',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Find trusted roadside support quickly',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              const _SplashProgress(),
              const SizedBox(height: AppSpacing.md),
              Text('Version 3.0.0',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashProgress extends StatelessWidget {
  const _SplashProgress();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _line(AppColors.primary, 190),
        const SizedBox(height: AppSpacing.xs),
        _line(AppColors.secondary, 230),
        const SizedBox(height: AppSpacing.xs),
        _line(const Color(0xFF2D2300), 150),
      ],
    );
  }

  Widget _line(Color color, double width) {
    return Container(
      width: width,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }
}
