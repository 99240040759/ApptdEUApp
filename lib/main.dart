import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/firebase_options.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try { await AuthService().init(); } catch (e) { debugPrint('GoogleSignIn init skipped: $e'); }
  try { await NotificationService().init(); } catch (e) { debugPrint('Notification init skipped: $e'); }
  runApp(const ApptdApp());
}
