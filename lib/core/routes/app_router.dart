import 'package:go_router/go_router.dart';
import 'package:indira_love/features/auth/presentation/screens/welcome_screen.dart';
import 'package:indira_love/features/auth/presentation/screens/login_screen.dart';
import 'package:indira_love/features/auth/presentation/screens/signup_screen.dart';
import 'package:indira_love/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:indira_love/features/discover/presentation/screens/discover_screen.dart';
import 'package:indira_love/features/messaging/presentation/screens/messages_screen.dart';
import 'package:indira_love/features/messaging/presentation/screens/conversation_screen.dart';
import 'package:indira_love/features/matches/presentation/screens/matches_screen.dart';
import 'package:indira_love/features/social/presentation/screens/social_screen.dart';
import 'package:indira_love/features/gifts/presentation/screens/gifts_screen.dart';
import 'package:indira_love/features/profile/presentation/screens/profile_screen.dart';
import 'package:indira_love/features/profile/presentation/screens/user_profile_detail_screen.dart';
import 'package:indira_love/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:indira_love/features/profile/presentation/screens/safety_screen.dart';
import 'package:indira_love/features/profile/presentation/screens/privacy_screen.dart';
import 'package:indira_love/features/subscription/presentation/screens/subscription_screen.dart';
import 'package:indira_love/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:indira_love/features/verification/presentation/screens/selfie_verification_screen.dart';
import 'package:indira_love/features/verification/presentation/screens/id_verification_screen.dart';
import 'package:indira_love/features/likes/presentation/screens/likes_screen.dart';
import 'package:indira_love/features/profile/presentation/screens/developer_settings_screen.dart';
import 'package:indira_love/features/activity/presentation/screens/activity_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/welcome',
    routes: [
      // Welcome & Authentication
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Main App Screens
      GoRoute(
        path: '/discover',
        builder: (context, state) => const DiscoverScreen(),
      ),
      GoRoute(
        path: '/messages',
        builder: (context, state) => const MessagesScreen(),
      ),
      GoRoute(
        path: '/matches',
        builder: (context, state) => const MatchesScreen(),
      ),
      GoRoute(
        path: '/likes',
        builder: (context, state) => const LikesScreen(),
      ),
      GoRoute(
        path: '/activity',
        builder: (context, state) => const ActivityScreen(),
      ),
      GoRoute(
        path: '/social',
        builder: (context, state) => const SocialScreen(),
      ),
      GoRoute(
        path: '/gifts',
        builder: (context, state) => const GiftsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/safety',
        builder: (context, state) => const SafetyScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/user-profile/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return UserProfileDetailScreen(userId: userId);
        },
      ),
      GoRoute(
        path: '/conversation/:matchId/:otherUserId/:otherUserName',
        builder: (context, state) {
          final matchId = state.pathParameters['matchId']!;
          final otherUserId = state.pathParameters['otherUserId']!;
          final otherUserName = state.pathParameters['otherUserName']!;
          final otherUserPhoto = state.uri.queryParameters['photo'];
          return ConversationScreen(
            matchId: matchId,
            otherUserId: otherUserId,
            otherUserName: otherUserName,
            otherUserPhoto: otherUserPhoto,
          );
        },
      ),

      // Admin Panel
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),

      // Verification
      GoRoute(
        path: '/verification',
        builder: (context, state) => const SelfieVerificationScreen(),
      ),
      GoRoute(
        path: '/id-verification',
        builder: (context, state) => const IdVerificationScreen(),
      ),

      // Developer Settings
      GoRoute(
        path: '/developer-settings',
        builder: (context, state) => const DeveloperSettingsScreen(),
      ),
    ],
  );
}
