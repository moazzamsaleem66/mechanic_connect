import 'package:flutter/material.dart';

import 'app/mechanic_connect_app.dart';
import 'l10n/app_locale.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLocale.loadSavedLocale();
  runApp(const MechanicConnectApp());
}
