// Spec: docs/specs/pages/* (shell que hospeda as 4 páginas)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/auth_provider.dart';
import '../acerto/acerto_page.dart';
import '../consulta/consulta_page.dart';
import '../detalhe/detalhe_page.dart';
import '../lancamento/lancamento_page.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  static const _destinations = [
    (icon: Icons.dashboard_outlined, label: 'Consulta'),
    (icon: Icons.list_alt_outlined, label: 'Detalhe'),
    (icon: Icons.add_circle_outline, label: 'Lançamento'),
    (icon: Icons.handshake_outlined, label: 'Acerto'),
  ];

  static const _pages = <Widget>[
    ConsultaPage(),
    DetalhePage(),
    LancamentoPage(),
    AcertoPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_destinations[_index].label),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final d in _destinations)
            NavigationDestination(icon: Icon(d.icon), label: d.label),
        ],
      ),
    );
  }
}
