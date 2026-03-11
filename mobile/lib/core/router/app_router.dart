import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../screens/profile/resume_upload_screen.dart';
import '../../screens/jobs/job_search_screen.dart';
import '../../screens/jobs/job_detail_screen.dart';
import '../../screens/jobs/apply_screen.dart';
import '../../screens/applications/history_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final auth = authState.valueOrNull;

      // Still loading — stay put
      if (authState.isLoading || auth == null) return null;

      final isAuthenticated = auth.status == AuthStatus.authenticated;
      final onAuthPage = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/';

      if (!isAuthenticated && !onAuthPage) return '/';
      if (isAuthenticated && onAuthPage) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => DashboardScreen(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const JobSearchScreen(),
          ),
          GoRoute(
            path: '/jobs/:url',
            builder: (_, state) => JobDetailScreen(
              jobUrl: Uri.decodeComponent(state.pathParameters['url']!),
            ),
          ),
          GoRoute(
            path: '/apply',
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>;
              return ApplyScreen(jobData: extra);
            },
          ),
          GoRoute(
            path: '/profiles',
            builder: (_, __) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/profiles/new',
            builder: (_, __) => const EditProfileScreen(),
          ),
          GoRoute(
            path: '/profiles/:id/edit',
            builder: (_, state) => EditProfileScreen(
              profileId: int.parse(state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/profiles/:id/resume',
            builder: (_, state) => ResumeUploadScreen(
              profileId: int.parse(state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/applications',
            builder: (_, __) => const HistoryScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
});
