import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:indira_love/firebase_options.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/core/routes/app_router.dart';
import 'package:indira_love/core/services/notification_service.dart';
import 'package:indira_love/core/services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Google Mobile Ads SDK
  await MobileAds.instance.initialize();

  // Initialize notification service
  await NotificationService().initialize();

  // Initialize push notifications
  await PushNotificationService().initialize();

  runApp(const ProviderScope(child: IndiraLoveApp()));
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class IndiraLoveApp extends StatelessWidget {
  const IndiraLoveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Indira Love',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: AppRouter.router,
    );
  }
}
