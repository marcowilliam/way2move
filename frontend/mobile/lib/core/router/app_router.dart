import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/dashboard/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';
import '../../features/compensations/presentation/pages/compensation_detail_page.dart';
import '../../features/compensations/presentation/pages/compensation_profile_page.dart';
import '../../features/calendar/presentation/pages/calendar_page.dart';
import '../../features/goals/presentation/pages/goal_detail_page.dart';
import '../../features/goals/presentation/pages/goal_list_page.dart';
import '../../features/goals/presentation/pages/goal_setup_page.dart';
import '../../features/profile/presentation/pages/onboarding_flow.dart';
import '../../features/profile/presentation/pages/profile_edit_page.dart';
import '../../features/assessments/presentation/pages/assessment_history_page.dart';
import '../../features/assessments/presentation/pages/initial_assessment_flow.dart';
import '../../features/exercises/presentation/pages/exercise_detail_page.dart';
import '../../features/exercises/presentation/pages/exercise_list_page.dart';
import '../../features/programs/presentation/pages/program_builder_page.dart';
import '../../features/programs/presentation/pages/program_detail_page.dart';
import '../../features/journal/domain/entities/journal_entry.dart';
import '../../features/journal/domain/services/entity_extraction_service.dart';
import '../../features/journal/presentation/pages/journal_entry_page.dart';
import '../../features/journal/presentation/pages/journal_history_page.dart';
import '../../features/journal/presentation/pages/review_auto_created_page.dart';
import '../../features/sessions/presentation/pages/create_standalone_session_page.dart';
import '../../features/sessions/presentation/pages/session_summary_page.dart';
import '../../features/sessions/presentation/pages/session_view.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final profileAsync = ref.watch(profileStreamProvider);

  return GoRouter(
    initialLocation: Routes.home,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isOnAuthRoute = state.matchedLocation.startsWith(Routes.auth);
      final isOnboarding = state.matchedLocation == Routes.onboarding;

      if (authState.isLoading) return null;
      if (!isLoggedIn && !isOnAuthRoute) return Routes.login;
      if (isLoggedIn && isOnAuthRoute) return Routes.home;

      // Wait for profile to load before checking onboarding
      if (isLoggedIn && profileAsync.isLoading) return null;

      if (isLoggedIn) {
        final profile = profileAsync.valueOrNull;
        final onboardingDone = profile?.onboardingComplete ?? false;

        // Forward: completed onboarding → leave the onboarding screen
        if (isOnboarding && onboardingDone) return Routes.home;

        // Backward: not done yet and not already on onboarding → send there
        if (!isOnboarding && !onboardingDone) return Routes.onboarding;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: Routes.login,
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginPage(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: Routes.signup,
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SignUpPage(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      ShellRoute(
        builder: (_, __, child) => _AppScaffold(child: child),
        routes: [
          GoRoute(
            path: Routes.home,
            pageBuilder: (_, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const HomePage(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: Routes.calendar,
            pageBuilder: (_, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const CalendarPage(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: Routes.exercises,
            pageBuilder: (_, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ExerciseListPage(),
              transitionsBuilder: _fadeTransition,
            ),
            routes: [
              GoRoute(
                path: ':exerciseId',
                pageBuilder: (_, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: ExerciseDetailPage(
                    exerciseId: state.pathParameters['exerciseId']!,
                  ),
                  transitionsBuilder: _slideTransition,
                ),
              ),
            ],
          ),
          GoRoute(
            path: Routes.goals,
            pageBuilder: (_, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const GoalListPage(),
              transitionsBuilder: _fadeTransition,
            ),
            routes: [
              GoRoute(
                path: ':goalId',
                pageBuilder: (_, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: GoalDetailPage(
                    goalId: state.pathParameters['goalId']!,
                  ),
                  transitionsBuilder: _slideTransition,
                ),
              ),
            ],
          ),
          GoRoute(
            path: Routes.profile,
            pageBuilder: (_, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ProfilePage(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: Routes.programs,
            pageBuilder: (_, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ProgramDetailPage(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
        ],
      ),
      GoRoute(
        path: Routes.programBuilder,
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: ProgramBuilderPage(
            fromAssessmentId: state.uri.queryParameters['fromAssessment'],
          ),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: Routes.sessionActive,
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SessionView(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: Routes.sessionStandalone,
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CreateStandaloneSessionPage(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: '/session/summary/:sessionId',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: SessionSummaryPage(
            sessionId: state.pathParameters['sessionId']!,
          ),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: Routes.assessment,
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const InitialAssessmentFlow(),
          transitionsBuilder: _slideTransition,
        ),
        routes: [
          GoRoute(
            path: 'history',
            pageBuilder: (_, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const AssessmentHistoryPage(),
              transitionsBuilder: _slideTransition,
            ),
          ),
        ],
      ),
      GoRoute(
        path: Routes.onboarding,
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingFlow(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: Routes.profileEdit,
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ProfileEditPage(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: Routes.compensationProfile,
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CompensationProfilePage(),
          transitionsBuilder: _slideTransition,
        ),
        routes: [
          GoRoute(
            path: ':compensationId',
            pageBuilder: (_, state) => CustomTransitionPage(
              key: state.pageKey,
              child: CompensationDetailPage(
                compensationId: state.pathParameters['compensationId']!,
              ),
              transitionsBuilder: _slideTransition,
            ),
          ),
        ],
      ),
      GoRoute(
        path: Routes.goalsSetup,
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: GoalSetupPage(
            fromAssessmentId: state.uri.queryParameters['fromAssessment'],
          ),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: Routes.journalEntry,
        pageBuilder: (_, state) {
          final typeStr = state.uri.queryParameters['type'] ?? 'general';
          final sessionId = state.uri.queryParameters['sessionId'];
          final type = JournalType.values.firstWhere(
            (t) => t.name == typeStr,
            orElse: () => JournalType.general,
          );
          return CustomTransitionPage(
            key: state.pageKey,
            child: JournalEntryPage(
              type: type,
              linkedSessionId: sessionId,
            ),
            transitionsBuilder: _slideTransition,
          );
        },
      ),
      GoRoute(
        path: Routes.journalHistory,
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const JournalHistoryPage(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: Routes.reviewAutoCreated,
        pageBuilder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return CustomTransitionPage(
            key: state.pageKey,
            child: ReviewAutoCreatedPage(
              journalId: extra['journalId'] as String? ?? '',
              sessions: (extra['sessions'] as List<ExtractedSession>?) ?? [],
              meals: (extra['meals'] as List<ExtractedMeal>?) ?? [],
              bodyMentions:
                  (extra['bodyMentions'] as List<ExtractedBodyMention>?) ?? [],
            ),
            transitionsBuilder: _slideTransition,
          );
        },
      ),
    ],
  );
});

Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
    child: child,
  );
}

Widget _slideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
    child: child,
  );
}

class _AppScaffold extends ConsumerWidget {
  final Widget child;
  const _AppScaffold({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onNavTap(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_outlined),
            activeIcon: Icon(Icons.fitness_center),
            label: 'Exercises',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag_outlined),
            activeIcon: Icon(Icons.flag),
            label: 'Goals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  int _locationToIndex(String location) {
    if (location.startsWith(Routes.calendar)) return 1;
    if (location.startsWith(Routes.exercises)) return 2;
    if (location.startsWith(Routes.goals)) return 3;
    if (location.startsWith(Routes.profile)) return 4;
    return 0;
  }

  void _onNavTap(BuildContext context, int index) {
    const routes = [
      Routes.home,
      Routes.calendar,
      Routes.exercises,
      Routes.goals,
      Routes.profile,
    ];
    context.go(routes[index]);
  }
}
