import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:indira_love/firebase_options.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/core/routes/app_router.dart';
import 'package:indira_love/core/l10n/app_localizations.dart';
import 'package:indira_love/core/l10n/locale_provider.dart';
import 'package:indira_love/core/services/notification_service.dart';
import 'package:indira_love/core/services/push_notification_service.dart';
import 'package:indira_love/core/services/logger_service.dart';
import 'package:indira_love/core/services/analytics_service.dart';
import 'package:indira_love/core/services/performance_monitoring_service.dart';
import 'package:indira_love/core/services/remote_config_service.dart';
import 'package:indira_love/core/services/app_check_service.dart';
import 'package:indira_love/core/services/revenuecat_service.dart';
import 'package:indira_love/core/services/review_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:indira_love/features/video_call/presentation/screens/incoming_call_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables (optional, don't block if missing)
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      logger.warning('Warning: .env file not found, continuing without it');
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

    // Initialize RevenueCat
    await revenueCatService.initialize();

    // Initialize notification service (non-blocking)
    NotificationService().initialize().catchError((e) {
      logger.error('Notification service initialization failed', error: e);
    });

    // Initialize push notifications (non-blocking)
    PushNotificationService().initialize().catchError((e) {
      logger.error('Push notification initialization failed', error: e);
    });
  } catch (e) {
    logger.error('Initialization error: $e');
  }

  runApp(const ProviderScope(child: IndiraLoveApp()));
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class IndiraLoveApp extends ConsumerStatefulWidget {
  const IndiraLoveApp({super.key});

  @override
  ConsumerState<IndiraLoveApp> createState() => _IndiraLoveAppState();
}

class _IndiraLoveAppState extends ConsumerState<IndiraLoveApp> {
  StreamSubscription? _callSub;

  @override
  void initState() {
    super.initState();
    _listenForIncomingCalls();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _callSub?.cancel();
      if (user != null) {
        _listenForIncomingCalls();
        // Check if it's time to show Google Play review (1 day after signup)
        reviewService.checkAndRequestReview();
      }
    });
  }

  void _listenForIncomingCalls() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _callSub = FirebaseFirestore.instance
        .collection('call_notifications')
        .where('targetId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final ctx = navigatorKey.currentContext;
        if (ctx == null) continue;

        Navigator.of(ctx).push(
          MaterialPageRoute(
            builder: (_) => IncomingCallScreen(
              sessionId: data['sessionId'] ?? '',
              callerId: data['callerId'] ?? '',
              callerName: data['callerName'] ?? 'Unknown',
              callType: data['callType'] ?? 'video',
              callerPhoto: data['callerPhoto'] as String?,
            ),
          ),
        );
        doc.reference.update({'status': 'shown'});
      }
    });
  }

  @override
  void dispose() {
    _callSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Indira Love',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: AppRouter.router,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
