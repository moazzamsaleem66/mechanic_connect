import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../auth/data/auth_session_store.dart';
import '../../auth/presentation/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoggingOut = false;

  Future<void> _onLogout() async {
    if (_isLoggingOut) return;

    setState(() => _isLoggingOut = true);
    try {
      await FirebaseAuth.instance.signOut();
      await AuthSessionStore.clear();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(LoginScreen.routeName, (route) => false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.homeLogoutFailed)),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            children: [
              const Spacer(),
              Icon(
                Icons.home_repair_service_outlined,
                color: AppColors.primary.withValues(alpha: 0.92),
                size: 84,
              ),
              const SizedBox(height: 18),
              Text(
                context.l10n.homeComingSoonTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1D2330),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.homeComingSoonSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6D7380),
                  height: 1.45,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoggingOut ? null : _onLogout,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _isLoggingOut
                        ? context.l10n.homeLoggingOut
                        : context.l10n.homeLogoutButton,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
