import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:indira_love/core/routes/page_transitions.dart';
import 'package:indira_love/core/widgets/main_scaffold.dart';
import 'package:indira_love/features/auth/presentation/screens/welcome_screen.dart';
import 'package:indira_love/features/auth/presentation/screens/login_screen.dart';
import 'package:indira_love/features/auth/presentation/screens/signup_screen.dart';
import 'package:indira_love/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:indira_love/features/discover/presentation/screens/discover_screen.dart';
import 'package:indira_love/features/messaging/presentation/screens/messages_screen.dart';
import 'package:indira_love/features/messaging/presentation/screens/conversation_screen.dart';
import 'package:indira_love/features/social/presentation/screens/social_screen.dart';
import 'package:indira_love/features/gifts/presentation/screens/gifts_screen.dart';
import 'package:indira_love/features/profile/presentation/screens/user_profile_detail_screen.dart';
import 'package:indira_love/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:indira_love/features/profile/presentation/screens/safety_screen.dart';
import 'package:indira_love/features/profile/presentation/screens/privacy_screen.dart';
import 'package:indira_love/features/subscription/presentation/screens/subscription_screen.dart';
import 'package:indira_love/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:indira_love/features/verification/presentation/screens/selfie_verification_screen.dart';
import 'package:indira_love/features/verification/presentation/screens/id_verification_screen.dart';
import 'package:indira_love/features/profile/presentation/screens/developer_settings_screen.dart';
import 'package:indira_love/features/activity/presentation/screens/activity_screen.dart';
import 'package:indira_love/features/entertainment/presentation/screens/entertainment_screen.dart';
import 'package:indira_love/features/entertainment/presentation/screens/love_language_quiz_screen.dart';
import 'package:indira_love/features/entertainment/presentation/screens/love_language_result_screen.dart';
import 'package:indira_love/features/entertainment/presentation/screens/trivia_screen.dart';
import 'package:indira_love/features/entertainment/presentation/screens/this_or_that_screen.dart';
import 'package:indira_love/features/entertainment/presentation/screens/multiplayer_hub_screen.dart';
import 'package:indira_love/features/entertainment/presentation/screens/would_you_rather_screen.dart';
import 'package:indira_love/features/entertainment/presentation/screens/compatibility_screen.dart';
import 'package:indira_love/features/festival/presentation/screens/festival_screen.dart';
import 'package:indira_love/features/kundli/presentation/screens/kundli_screen.dart';
import 'package:indira_love/features/safety/presentation/screens/safety_checkin_screen.dart';
import 'package:indira_love/features/language/presentation/screens/language_screen.dart';
import 'package:indira_love/features/profile/presentation/screens/cultural_preferences_screen.dart';
import 'package:indira_love/features/likes/presentation/screens/likes_screen.dart';
import 'package:indira_love/features/profile/presentation/screens/profile_screen.dart';

// Navigator keys for each tab branch
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _discoverNavKey = GlobalKey<NavigatorState>(debugLabel: 'discover');
final _giftsNavKey = GlobalKey<NavigatorState>(debugLabel: 'gifts');
final _messagesNavKey = GlobalKey<NavigatorState>(debugLabel: 'messages');
final _socialNavKey = GlobalKey<NavigatorState>(debugLabel: 'social');
final _entertainmentNavKey = GlobalKey<NavigatorState>(debugLabel: 'entertainment');

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/welcome',
    routes: [
      // ─── Authentication (no bottom nav) ───────────────────
      GoRoute(
        path: '/welcome',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => AppPageTransitions.fadeIn(
          key: state.pageKey,
          child: const WelcomeScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => AppPageTransitions.slideRight(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/signup',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => AppPageTransitions.slideRight(
          key: state.pageKey,
          child: const SignupScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => AppPageTransitions.slideRight(
          key: state.pageKey,
          child: const OnboardingScreen(),
        ),
      ),

      // ─── Main App with Bottom Navigation ──────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(
            currentIndex: navigationShell.currentIndex,
            onTabChanged: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
            child: navigationShell,
          );
        },
        branches: [
          // Tab 0: Discover
          StatefulShellBranch(
            navigatorKey: _discoverNavKey,
            routes: [
              GoRoute(
                path: '/discover',
                pageBuilder: (context, state) => AppPageTransitions.fadeIn(
                  key: state.pageKey,
                  child: const DiscoverScreen(),
                ),
              ),
            ],
          ),

          // Tab 1: Gifts
          StatefulShellBranch(
            navigatorKey: _giftsNavKey,
            routes: [
              GoRoute(
                path: '/gifts',
                pageBuilder: (context, state) => AppPageTransitions.fadeIn(
                  key: state.pageKey,
                  child: const GiftsScreen(),
                ),
              ),
            ],
          ),

          // Tab 2: Messages
          StatefulShellBranch(
            navigatorKey: _messagesNavKey,
            routes: [
              GoRoute(
                path: '/messages',
                pageBuilder: (context, state) => AppPageTransitions.fadeIn(
                  key: state.pageKey,
                  child: const MessagesScreen(),
                ),
              ),
            ],
          ),

          // Tab 3: Social
          StatefulShellBranch(
            navigatorKey: _socialNavKey,
            routes: [
              GoRoute(
                path: '/social',
                pageBuilder: (context, state) => AppPageTransitions.fadeIn(
                  key: state.pageKey,
                  child: const SocialScreen(),
                ),
              ),
            ],
          ),

          // Tab 4: Entertainment
          StatefulShellBranch(
            navigatorKey: _entertainmentNavKey,
            routes: [
              GoRoute(
                path: '/entertainment',
                pageBuilder: (context, state) => AppPageTransitions.fadeIn(
                  key: state.pageKey,
                  child: const EntertainmentScreen(),
                ),
              ),
            ],
          ),
        ],
      ),

      // ─── Likes & Profile (above bottom nav) ─────────────────
      GoRoute(
        path: '/likes',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => AppPageTransitions.slideRight(
          key: state.pageKey,
          child: const LikesScreen(),
        ),
      ),
      GoRoute(
        path: '/profile',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => AppPageTransitions.slideRight(
          key: state.pageKey,
          child: const ProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => AppPageTransitions.slideRight(
          key: state.pageKey,
          child: const ProfileScreen(),
        ),
      ),

      // ─── Detail screens (slide right, above bottom nav) ───
      GoRoute(
        path: '/user-profile/:userId',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return AppPageTransitions.slideRight(
            key: state.pageKey,
            child: UserProfileDetailScreen(userId: userId),
          );
        },
      ),
      GoRoute(
        path: '/conversation/:matchId/:otherUserId/:otherUserName',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final matchId = state.pathParameters['matchId']!;
          final otherUserId = state.pathParameters['otherUserId']!;
          final otherUserName = state.pathParameters['otherUserName']!;
          final otherUserPhoto = state.uri.queryParameters['photo'];
          return AppPageTransitions.slideRight(
            key: state.pageKey,
            child: ConversationScreen(
              matchId: matchId,
              otherUserId: otherUserId,
              otherUserName: otherUserName,
              otherUserPhoto: otherUserPhoto,
            ),
          );
        },
      ),
      GoRoute(
        path: '/edit-profile',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => AppPageTransitions.slideRight(
          key: state.pageKey,
          child: const EditProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/cultural-preferences',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => AppPageTransitions.slideRight(
          key: state.pageKey,
          child: const CulturalPreferencesScreen(),
        ),
      ),

      // ─── Modal screens (slide up, above bottom nav) ───────
      GoRoute(
        path: '/subscription',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => AppPageTransitions.slideUp(
          key: state.pageKey,
          child: const SubscriptionScreen(),
        ),
      ),
      GoRoute(
        path: '/safety',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => AppPageTransitions.slideUp(
          key: state.pageKey,
          child: const SafetyScreen(),
        ),
      ),
      GoRoute(
        path: '/privacy',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => AppPageTransitions.slideUp(
          key: state.pageKey,
          child: const PrivacyScreen(),
        ),
      ),
      GoRoute(
        path: '/language',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => AppPageTransitions.slideUp(
          key: state.pageKey,
          child: const LanguageScreen(),
        ),
      ),

      // ─── Other full-screen routes ─────────────────────────
      GoRoute(
        path: '/activity',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => AppPageTransitions.slideRight(
          key: state.pageKey,
          child: const ActivityScreen(),
        ),
      ),
      GoRoute(
        path: '/admin',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => AppPageTransitions.slideRight(
          key: state.pageKey,
          child: const AdminDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/verification',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => AppPageTransitions.slideRight(
          key: state.pageKey,
          child: const SelfieVerificationScreen(),
        ),
      ),
      GoRoute(
        path: '/id-verification',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => AppPageTransitions.slideRight(
          key: state.pageKey,
          child: const IdVerificationScreen(),
        ),
      ),
      GoRoute(
        path: '/developer-settings',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => AppPageTransitions.slideRight(
          key: state.pageKey,
          child: const DeveloperSettingsScreen(),
        ),
      ),

      // ─── Entertainment & Games ────────────────────────────
      GoRoute(
        path: '/love-language-quiz',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => AppPageTransitions.slideRight(
          key: state.pageKey,
          child: const LoveLanguageQuizScreen(),
        ),
      ),
      GoRoute(
        path: '/love-language-result',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => AppPageTransitions.slideRight(
          key: state.pageKey,
          child: const LoveLanguageResultScreen(),
        ),
      ),
      GoRoute(
        path: '/trivia',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => AppPageTransitions.slideRight(
          key: state.pageKey,
          child: const TriviaScreen(),
        ),
      ),
      GoRoute(
        path: '/this-or-that',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => AppPageTransitions.slideRight(
          key: state.pageKey,
          child: const ThisOrThatScreen(),
        ),
      ),
      GoRoute(
        path: '/multiplayer-hub',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final game = state.uri.queryParameters['game'] ?? 'would_you_rather';
          return AppPageTransitions.slideRight(
            key: state.pageKey,
            child: MultiplayerHubScreen(gameType: game),
          );
        },
      ),
      GoRoute(
        path: '/would-you-rather/:sessionId',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return AppPageTransitions.slideRight(
            key: state.pageKey,
            child: WouldYouRatherScreen(sessionId: sessionId),
          );
        },
      ),
      GoRoute(
        path: '/compatibility/:sessionId',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return AppPageTransitions.slideRight(
            key: state.pageKey,
            child: CompatibilityScreen(sessionId: sessionId),
          );
        },
      ),

      // ─── Special Features ─────────────────────────────────
      GoRoute(
        path: '/festivals',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => AppPageTransitions.slideRight(
          key: state.pageKey,
          child: const FestivalScreen(),
        ),
      ),
      GoRoute(
        path: '/kundli',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final otherUserId = state.uri.queryParameters['userId'];
          return AppPageTransitions.slideRight(
            key: state.pageKey,
            child: KundliScreen(otherUserId: otherUserId),
          );
        },
      ),
      GoRoute(
        path: '/safety-checkin',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => AppPageTransitions.slideRight(
          key: state.pageKey,
          child: const SafetyCheckinScreen(),
        ),
      ),
    ],
  );
}
