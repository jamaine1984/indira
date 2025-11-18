import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:indira_love/firebase_options.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/core/routes/app_router.dart';
import 'package:indira_love/core/config/env_config.dart';

// Import all production services
import 'package:indira_love/core/services/logger_service.dart';
import 'package:indira_love/core/services/analytics_service.dart';
import 'package:indira_love/core/services/validation_service.dart';
import 'package:indira_love/core/services/encryption_service.dart';
import 'package:indira_love/core/services/rate_limiter_service.dart';
import 'package:indira_love/core/services/notification_service.dart';
import 'package:indira_love/core/services/push_notification_service.dart';

// Global instances
late LoggerService logger;
late AnalyticsService analytics;
late ValidationService validator;
late EncryptionService encryption;
late RateLimiterService rateLimiter;

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Run in error zone for crash handling
  await runZonedGuarded<Future<void>>(() async {
    try {
      // 1. Load environment configuration
      await _initializeEnvironment();

      // 2. Initialize Firebase
      await _initializeFirebase();

      // 3. Initialize crash reporting
      await _initializeCrashlytics();

      // 4. Initialize core services
      await _initializeServices();

      // 5. Initialize ads (production)
      await _initializeAds();

      // 6. Initialize notifications
      await _initializeNotifications();

      // Start the app
      runApp(
        ProviderScope(
          observers: [AnalyticsObserver()],
          child: const IndiraLoveApp(),
        ),
      );
    } catch (error, stack) {
      // Log fatal initialization errors
      if (logger != null) {
        await logger.error('Fatal initialization error', error: error, stackTrace: stack);
      }

      // Show error app
      runApp(MaterialApp(
        home: InitializationErrorScreen(error: error.toString()),
      ));
    }
  }, (error, stack) {
    // Catch any errors that weren't caught by the try-catch
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

// Initialize environment configuration
Future<void> _initializeEnvironment() async {
  try {
    await dotenv.load(fileName: '.env');
    await EnvConfig.initialize();
  } catch (e) {
    // Use default configuration if .env is missing
    print('Using default configuration: $e');
  }
}

// Initialize Firebase
Future<void> _initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

// Initialize Crashlytics
Future<void> _initializeCrashlytics() async {
  // Pass all uncaught errors to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Pass uncaught asynchronous errors to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

// Initialize core services
Future<void> _initializeServices() async {
  // Initialize logger first
  logger = LoggerService();
  await logger.initialize();

  // Initialize analytics
  analytics = AnalyticsService();
  await analytics.initialize();

  // Initialize validation
  validator = ValidationService();
  await validator.initialize();

  // Initialize encryption
  encryption = EncryptionService();
  await encryption.initialize();

  // Initialize rate limiter
  rateLimiter = RateLimiterService();

  await logger.info('All core services initialized');
}

// Initialize production ads
Future<void> _initializeAds() async {
  try {
    // Initialize Google Mobile Ads with production configuration
    final RequestConfiguration requestConfiguration = RequestConfiguration(
      // Remove test device IDs for production
      testDeviceIds: [], // Empty for production

      // Set child-directed treatment for COPPA compliance
      tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,

      // Maximum ad content rating
      maxAdContentRating: MaxAdContentRating.ma, // Mature audiences for dating app
    );

    MobileAds.instance.updateRequestConfiguration(requestConfiguration);

    // Initialize ads SDK
    await MobileAds.instance.initialize();

    await logger.info('Production ads initialized');
  } catch (e) {
    await logger.error('Failed to initialize ads', error: e);
  }
}

// Initialize notifications
Future<void> _initializeNotifications() async {
  try {
    // Initialize local notifications
    final notificationService = NotificationService();
    await notificationService.initialize();

    // Initialize push notifications
    final pushService = PushNotificationService();
    await pushService.initialize();

    await logger.info('Notifications initialized');
  } catch (e) {
    await logger.error('Failed to initialize notifications', error: e);
  }
}

// Analytics observer for Riverpod
class AnalyticsObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    analytics.logEvent('provider_updated', parameters: {
      'provider': provider.name ?? provider.runtimeType.toString(),
    });
  }
}

// Main app widget
class IndiraLoveApp extends StatefulWidget {
  const IndiraLoveApp({super.key});

  @override
  State<IndiraLoveApp> createState() => _IndiraLoveAppState();
}

class _IndiraLoveAppState extends State<IndiraLoveApp> with WidgetsBindingObserver {
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: analytics);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Log app start
    analytics.logAppOpen();
    logger.info('App started');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Track app lifecycle
    switch (state) {
      case AppLifecycleState.resumed:
        analytics.logEvent('app_resumed');
        logger.info('App resumed');
        break;
      case AppLifecycleState.paused:
        analytics.logEvent('app_paused');
        logger.info('App paused');
        break;
      case AppLifecycleState.detached:
        analytics.logEvent('app_detached');
        logger.info('App detached');
        break;
      case AppLifecycleState.inactive:
        analytics.logEvent('app_inactive');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Indira Love',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: AppRouter.router,
      navigatorObservers: [observer],
    );
  }
}

// Error screen for initialization failures
class InitializationErrorScreen extends StatelessWidget {
  final String error;

  const InitializationErrorScreen({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Oops! Something went wrong',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'We couldn\'t start the app. Please try again later.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Restart app
                    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFFF6B6B),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Close App',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}