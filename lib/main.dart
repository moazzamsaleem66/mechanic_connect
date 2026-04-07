import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/mechanic_connect_app.dart';
import 'l10n/app_locale.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await AppLocale.loadSavedLocale();
  runApp(const MechanicConnectApp());
}
