import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Run in background — never block app startup
  AuthService().init().catchError((_) {});
  NotificationService.init().then((_) {
    NotificationService.onNotificationTap = (route) {
      ApptdApp.navigatorKey.currentState?.pushNamed(route);
    };
  }).catchError((_) {});
  runApp(const ApptdApp());
}
