import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static late EnvConfig _instance;

  // Firebase Configuration
  final String firebaseApiKey;
  final String firebaseAuthDomain;
  final String firebaseProjectId;
  final String firebaseStorageBucket;
  final String firebaseMessagingSenderId;
  final String firebaseAppId;
  final String? firebaseMeasurementId;

  // ZegoCloud Configuration
  final String zegoCloudAppId;
  final String zegoCloudAppSign;
  final String zegoCloudServerSecret;

  // Google Services
  final String googleWebClientId;

  // Stripe Configuration
  final String? stripePublishableKey;
  final String? stripeSecretKey;

  // Encryption
  final String messageEncryptionKey;
  final String jwtSecret;

  // Environment
  final String environment;
  final bool isDebugMode;
  final List<String> adminEmails;

  EnvConfig._({
    required this.firebaseApiKey,
    required this.firebaseAuthDomain,
    required this.firebaseProjectId,
    required this.firebaseStorageBucket,
    required this.firebaseMessagingSenderId,
    required this.firebaseAppId,
    this.firebaseMeasurementId,
    required this.zegoCloudAppId,
    required this.zegoCloudAppSign,
    required this.zegoCloudServerSecret,
    required this.googleWebClientId,
    this.stripePublishableKey,
    this.stripeSecretKey,
    required this.messageEncryptionKey,
    required this.jwtSecret,
    required this.environment,
    required this.isDebugMode,
    required this.adminEmails,
  });

  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');

    _instance = EnvConfig._(
      firebaseApiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
      firebaseAuthDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '',
      firebaseProjectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
      firebaseStorageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
      firebaseMessagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
      firebaseAppId: dotenv.env['FIREBASE_APP_ID'] ?? '',
      firebaseMeasurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'],
      zegoCloudAppId: dotenv.env['ZEGOCLOUD_APP_ID'] ?? '',
      zegoCloudAppSign: dotenv.env['ZEGOCLOUD_APP_SIGN'] ?? '',
      zegoCloudServerSecret: dotenv.env['ZEGOCLOUD_SERVER_SECRET'] ?? '',
      googleWebClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '',
      stripePublishableKey: dotenv.env['STRIPE_PUBLISHABLE_KEY'],
      stripeSecretKey: dotenv.env['STRIPE_SECRET_KEY'],
      messageEncryptionKey: dotenv.env['MESSAGE_ENCRYPTION_KEY'] ?? '',
      jwtSecret: dotenv.env['JWT_SECRET'] ?? '',
      environment: dotenv.env['ENVIRONMENT'] ?? 'development',
      isDebugMode: dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true',
      adminEmails: (dotenv.env['ADMIN_EMAILS'] ?? '').split(',').map((e) => e.trim()).toList(),
    );

    _validateConfig();
  }

  static void _validateConfig() {
    final missingKeys = <String>[];

    if (_instance.firebaseApiKey.isEmpty) missingKeys.add('FIREBASE_API_KEY');
    if (_instance.firebaseProjectId.isEmpty) missingKeys.add('FIREBASE_PROJECT_ID');
    if (_instance.messageEncryptionKey.isEmpty) missingKeys.add('MESSAGE_ENCRYPTION_KEY');
    if (_instance.jwtSecret.isEmpty) missingKeys.add('JWT_SECRET');

    if (missingKeys.isNotEmpty) {
      throw Exception('Missing required environment variables: ${missingKeys.join(', ')}');
    }
  }

  static EnvConfig get instance {
    return _instance;
  }

  bool get isProduction => environment == 'production';
  bool get isDevelopment => environment == 'development';
  bool get isStaging => environment == 'staging';
}