# Flutter Frontend — Navigation

## Tool: GoRouter

GoRouter is the sole navigation solution. Never use `Navigator.push()` or `Navigator.pushNamed()` for app-level navigation. GoRouter gives us declarative routing, deep link support, and auth-gating in one place.

## Router location
```
core/router/
├── app_router.dart         # GoRouter instance (Provider)
├── routes.dart             # route path constants
└── guards/
    └── auth_guard.dart     # redirect logic for unauthenticated users
```

## Router definition
```dart
// core/router/app_router.dart
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: Routes.home,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isOnAuthRoute = state.matchedLocation.startsWith(Routes.auth);

      if (!isLoggedIn && !isOnAuthRoute) return Routes.login;
      if (isLoggedIn && isOnAuthRoute) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.login,
        builder: (_, __) => const LoginPage(),
      ),
      ShellRoute(
        builder: (_, __, child) => AppScaffold(child: child),
        routes: [
          GoRoute(path: Routes.home, builder: (_, __) => const HomePage()),
          GoRoute(path: Routes.profile, builder: (_, __) => const ProfilePage()),
          GoRoute(
            path: '${Routes.session}/:sessionId',
            builder: (_, state) => SessionDetailPage(
              sessionId: state.pathParameters['sessionId']!,
            ),
          ),
        ],
      ),
    ],
  );
});
```

## Route constants
```dart
// core/router/routes.dart
abstract class Routes {
  static const auth = '/auth';
  static const login = '/auth/login';
  static const signup = '/auth/signup';
  static const home = '/';
  static const profile = '/profile';
  static const session = '/session';
  static const exercises = '/exercises';
  static const programs = '/programs';
  static const calendar = '/calendar';
  static const progress = '/progress';
  static const assessment = '/assessment';
}
```

## Navigating
```dart
// Go to a route (replaces current location)
context.go(Routes.home);

// Push a route (adds to history, back button works)
context.push(Routes.profile);

// Push with parameters
context.push('${Routes.session}/$sessionId');

// Pop back
context.pop();
```

## Auth gating
The `redirect` function in GoRouter handles auth. It watches `authStateProvider` reactively — when auth state changes (login/logout), the router automatically redirects without any manual navigation calls.

## Deep linking
GoRouter handles deep links automatically. Configure the scheme in `AndroidManifest.xml` and `Info.plist`. No extra code needed in the router.

## Passing data between routes
Prefer navigation by ID, not by object. Pass the `id`, load the entity from a provider on the destination screen.
```dart
// Good — pass an ID
context.push('${Routes.session}/$sessionId');

// Avoid — passing full objects couples screens
context.push(Routes.session, extra: session); // only use `extra` for non-deep-linkable flows
```
