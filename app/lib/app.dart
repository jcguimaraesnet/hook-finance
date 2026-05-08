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
  late final _AuthListenable _authListenable;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authListenable = _AuthListenable(ref);
    _router = GoRouter(
      initialLocation: '/login',
      refreshListenable: _authListenable,
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
    Future.microtask(() => ref.read(authProvider.notifier).hydrate());
  }

  @override
  void dispose() {
    _authListenable.dispose();
    _router.dispose();
    super.dispose();
  }

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

/// Bridge entre Riverpod e go_router: dispara `notifyListeners` sempre que
/// authProvider muda. Usa `listenManual` (chamável fora de build); `ref.listen`
/// não funciona aqui porque exige contexto de build do Consumer.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(WidgetRef ref) {
    _sub = ref.listenManual<AuthState>(
      authProvider,
      (_, _) => notifyListeners(),
    );
  }

  late final ProviderSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
