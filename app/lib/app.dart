// Spec: docs/specs/pages/consulta.md (entry route)
// Spec: docs/specs/state/persistence.md (auth gate)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/login/login_screen.dart';
import 'features/shell/app_shell.dart';
import 'state/auth_provider.dart';
import 'theme/theme.dart';

class HookFinanceApp extends ConsumerStatefulWidget {
  const HookFinanceApp({super.key});

  @override
  ConsumerState<HookFinanceApp> createState() => _HookFinanceAppState();
}

class _HookFinanceAppState extends ConsumerState<HookFinanceApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _buildRouter();
    Future.microtask(() => ref.read(authProvider.notifier).hydrate());
  }

  GoRouter _buildRouter() => GoRouter(
        initialLocation: '/login',
        refreshListenable: _AuthListenable(ref),
        redirect: (context, state) {
          final auth = ref.read(authProvider);
          if (!auth.ready) return null;
          final atLogin = state.matchedLocation == '/login';
          if (auth.isAuthed && atLogin) return '/consulta';
          if (!auth.isAuthed && !atLogin) return '/login';
          return null;
        },
        routes: [
          GoRoute(
            path: '/login',
            builder: (_, _) => const LoginScreen(),
          ),
          GoRoute(
            path: '/consulta',
            builder: (_, _) => const AppShell(),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'hook-finance',
      theme: buildAppTheme(),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, _) => notifyListeners());
  }
  final WidgetRef _ref;
}
