// Spec: docs/specs/features/captura-notificacoes.md
//
// Bottom sheet pra escolher um app instalado no device. Lista é populada via
// installed_apps; busca textual sobre nome+packageName.

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

import '../../theme/bloom_colors.dart';
import '../../theme/bloom_typography.dart';

Future<String?> showAppPickerSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _AppPickerSheet(),
  );
}

class _AppPickerSheet extends StatefulWidget {
  const _AppPickerSheet();

  @override
  State<_AppPickerSheet> createState() => _AppPickerSheetState();
}

class _AppPickerSheetState extends State<_AppPickerSheet> {
  List<AppInfo>? _apps;
  String _query = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (kIsWeb || !Platform.isAndroid) {
      setState(() => _error = 'Só disponível no Android.');
      return;
    }
    try {
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: true,
        excludeNonLaunchableApps: true,
        withIcon: true,
      );
      if (!mounted) return;
      setState(() => _apps = apps);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final filtered = _filter(_apps ?? const <AppInfo>[], _query);

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        height: mq.size.height * 0.82,
        decoration: const BoxDecoration(
          color: BloomColors.bg3,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: BloomColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Escolher app',
                      style: BloomTypography.display(
                        fontSize: 18,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: BloomColors.inkSoft,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
              child: TextField(
                autofocus: false,
                decoration: const InputDecoration(
                  hintText: 'Buscar por nome ou pacote',
                  prefixIcon: Icon(Icons.search, size: 20),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),
            const Divider(height: 1, color: BloomColors.divider),
            Expanded(
              child: _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          _error!,
                          style: BloomTypography.geist(
                            fontSize: 13,
                            color: BloomColors.bad,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : _apps == null
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: BloomColors.violet,
                          ),
                        )
                      : filtered.isEmpty
                          ? Center(
                              child: Text(
                                _query.isEmpty
                                    ? 'Nenhum app encontrado.'
                                    : 'Sem matches pra "$_query".',
                                style: BloomTypography.geist(
                                  fontSize: 12.5,
                                  color: BloomColors.muted,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (_, i) {
                                final a = filtered[i];
                                return _AppRow(
                                  app: a,
                                  onTap: () =>
                                      Navigator.of(context).pop(a.packageName),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  List<AppInfo> _filter(List<AppInfo> apps, String q) {
    if (q.isEmpty) return apps;
    final low = q.toLowerCase();
    return apps
        .where((a) =>
            a.name.toLowerCase().contains(low) ||
            a.packageName.toLowerCase().contains(low))
        .toList();
  }
}

class _AppRow extends StatelessWidget {
  final AppInfo app;
  final VoidCallback onTap;

  const _AppRow({required this.app, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 38,
                height: 38,
                child: app.icon != null
                    ? Image.memory(app.icon!, gaplessPlayback: true)
                    : Container(
                        decoration: BoxDecoration(
                          color: BloomColors.bg1,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.android,
                            size: 20, color: BloomColors.muted),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.name,
                      style: BloomTypography.geist(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: BloomColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      app.packageName,
                      style: BloomTypography.mono(
                        fontSize: 11,
                        color: BloomColors.muted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
