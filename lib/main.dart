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
import 'package:indira_love/core/services/logger_service.dart';
import 'package:indira_love/core/services/analytics_service.dart';
import 'package:indira_love/core/services/performance_monitoring_service.dart';
import 'package:indira_love/core/services/remote_config_service.dart';
import 'package:indira_love/core/services/app_check_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables (optional, don't block if missing)
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      print('Warning: .env file not found, continuing without it');
    }

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Firebase App Check (must be before other Firebase services)
    await appCheck.initialize();

    // Initialize Firebase services
    await logger.initialize();
    await analytics.initialize();
    await performanceMonitoring.initialize();
    await remoteConfig.initialize();

    // Initialize Google Mobile Ads SDK
    MobileAds.instance.initialize();

    // Initialize notification service (non-blocking)
    NotificationService().initialize().catchError((e) {
      logger.error('Notification service initialization failed', error: e);
    });

    // Initialize push notifications (non-blocking)
    PushNotificationService().initialize().catchError((e) {
      logger.error('Push notification initialization failed', error: e);
    });
  } catch (e) {
    print('Initialization error: $e');
  }

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
