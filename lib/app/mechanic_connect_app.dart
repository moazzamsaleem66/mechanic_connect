import 'package:flutter/material.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/create_account_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/home/presentation/map_screen.dart';
import '../features/splash/presentation/intro_screen.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_localizations.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../l10n/l10n.dart';
import '../theme/theme.dart';

class MechanicConnectApp extends StatelessWidget {
  const MechanicConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLocale.current,
      builder: (context, locale, _) {
        return MaterialApp(
          locale: locale,
          onGenerateTitle: (context) => context.l10n.appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            if (deviceLocale == null) return L10n.fallbackLocale;
            for (final locale in supportedLocales) {
              if (locale.languageCode == deviceLocale.languageCode) {
                return locale;
              }
            }
            return L10n.fallbackLocale;
          },
          initialRoute: SplashScreen.routeName,
          routes: {
            SplashScreen.routeName: (_) => const SplashScreen(),
            LoginScreen.routeName: (_) => const LoginScreen(),
            CreateAccountScreen.routeName: (_) => const CreateAccountScreen(),
            ForgotPasswordScreen.routeName: (_) => const ForgotPasswordScreen(),
            IntroScreen.routeName: (_) => const IntroScreen(),
            HomeScreen.routeName: (_) => const HomeScreen(),
            MapScreen.routeName: (_) => const MapScreen(),
          },
        );
      },
    );
  }
}
