import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'routes.dart';

// Placeholder pages — replaced in their respective blocks
class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);

  return GoRouter(
    initialLocation: Routes.home,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isOnAuthRoute =
          state.matchedLocation.startsWith(Routes.auth);
      final isLoading = authState.isLoading;

      if (isLoading) return null;
      if (!isLoggedIn && !isOnAuthRoute) return Routes.login;
      if (isLoggedIn && isOnAuthRoute) return Routes.home;
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
              child: const _PlaceholderPage(title: 'Home'),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: Routes.calendar,
            pageBuilder: (_, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const _PlaceholderPage(title: 'Calendar'),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: Routes.exercises,
            pageBuilder: (_, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const _PlaceholderPage(title: 'Exercises'),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: Routes.progress,
            pageBuilder: (_, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const _PlaceholderPage(title: 'Progress'),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: Routes.profile,
            pageBuilder: (_, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const _PlaceholderPage(title: 'Profile'),
              transitionsBuilder: _fadeTransition,
            ),
          ),
        ],
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
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Progress',
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
    if (location.startsWith(Routes.progress)) return 3;
    if (location.startsWith(Routes.profile)) return 4;
    return 0;
  }

  void _onNavTap(BuildContext context, int index) {
    final routes = [
      Routes.home,
      Routes.calendar,
      Routes.exercises,
      Routes.progress,
      Routes.profile,
    ];
    context.go(routes[index]);
  }
}
