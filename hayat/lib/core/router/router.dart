import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/donor/presentation/donor_home_screen.dart';
import '../../features/donor/presentation/pre_donation_form_screen.dart';
import '../../features/donor/presentation/profile_screen.dart';
import '../../features/donor/presentation/complete_profile_screen.dart';
import '../../features/patient/presentation/activity_screen.dart';
import '../../features/patient/presentation/create_request_screen.dart';
import '../../features/home/presentation/scaffold_with_nav_bar.dart';
import '../../features/home/presentation/settings_screen.dart';
import '../../features/home/presentation/chat_screen.dart';
import '../../features/gamification/presentation/redeem_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

// Custom page transition
CustomTransitionPage<T> _buildPageWithTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Fade + Slide from right
      const begin = Offset(0.05, 0);
      const end = Offset.zero;
      final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeOutCubic));
      final offsetAnimation = animation.drive(tween);
      
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: offsetAnimation,
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final authStateStream = ref.watch(authRepositoryProvider).authStateChanges;
  
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _buildPageWithTransition(context: context, state: state, child: const LoginScreen()),
      ),
      GoRoute(
        path: '/complete-profile',
        pageBuilder: (context, state) => _buildPageWithTransition(context: context, state: state, child: const CompleteProfileScreen()),
      ),
      GoRoute(
        path: '/create-request',
        pageBuilder: (context, state) => _buildPageWithTransition(context: context, state: state, child: const CreateRequestScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => _buildPageWithTransition(context: context, state: state, child: const SettingsScreen()),
      ),
      GoRoute(
        path: '/chat',
        pageBuilder: (context, state) => _buildPageWithTransition(context: context, state: state, child: const ChatScreen()),
      ),
      GoRoute(
        path: '/redeem',
        pageBuilder: (context, state) => _buildPageWithTransition(context: context, state: state, child: const RedeemScreen()),
      ),
      // Authenticated Shell with 4 branches
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
           return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/donor-home',
                pageBuilder: (context, state) => _buildPageWithTransition(context: context, state: state, child: const DonorHomeScreen()),
                routes: [
                   GoRoute(
                    path: 'pre-donation/:type',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) {
                      final type = state.pathParameters['type'] ?? 'DEFAULT';
                      return _buildPageWithTransition(context: context, state: state, child: PreDonationFormScreen(hospitalType: type));
                    },
                  ),
                ]
              ),
            ],
          ),
          // Branch 1: Activity
          StatefulShellBranch(
             routes: [
               GoRoute(
                 path: '/activity',
                 pageBuilder: (context, state) => _buildPageWithTransition(context: context, state: state, child: const ActivityScreen()),
               ),
             ],
          ),
          // Branch 2: Redeem (Gamification)
          StatefulShellBranch(
             routes: [
               GoRoute(
                 path: '/redeem-tab',
                 pageBuilder: (context, state) => _buildPageWithTransition(context: context, state: state, child: const RedeemScreen()),
               ),
             ],
          ),
          // Branch 3: Profile
          StatefulShellBranch(
             routes: [
               GoRoute(
                 path: '/profile',
                 pageBuilder: (context, state) => _buildPageWithTransition(context: context, state: state, child: const ProfileScreen()),
               ),
             ],
          ),
        ],
      ),
    ],
  );
});
