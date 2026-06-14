import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // google-services.json is compiled into Android resources by the Gradle plugin.
  // No options needed — Firebase reads config automatically.
  await Firebase.initializeApp();
  try { await AuthService().init(); } catch (e) { debugPrint('GoogleSignIn init skipped: $e'); }
  try {
    await NotificationService.init();
    NotificationService.onNotificationTap = (route) {
      ApptdApp.navigatorKey.currentState?.pushNamed(route);
    };
  } catch (e) { debugPrint('Notification init skipped: $e'); }
  runApp(const ApptdApp());
}
